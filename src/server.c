/*
vim:set ts=2 sts=2 sw=2 expandtab:
*/

#include "byte.h"
#include "logger.h"
#include <stdio.h>
#include "case.h"
#include "env.h"
#include "buffer.h"
#include "strerr.h"
#include "ip4.h"
#include "uint16.h"
#include "ndelay.h"
#include "socket.h"
#include "droproot.h"
#include "qlog.h"
#include "response.h"
#include "dns.h"
#include "scan.h"

#include <sys/epoll.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/uio.h>

#define EVQUE_LEN 4096


extern char *fatal;
extern char *starting;
extern int cdb_cache(void);
extern int respond(char *,char *,char *);
extern void initialize(void);


static char ip[4];
static uint16 port;

static char buf[513];
static int len;

static char *q;

extern int dataini(void);

static int doit()
{
  unsigned int pos;
  char header[12];
  char qtype[2];
  char qclass[2];


  if (len >= sizeof buf) goto NOQ;
  pos = dns_packet_copy(buf,len,0,header,12); if (!pos) goto NOQ;
  if (header[2] & 128) goto NOQ;
  if (header[4]) goto NOQ;
  if (header[5] != 1) goto NOQ;

  pos = dns_packet_getname(buf,len,pos,&q); if (!pos) goto NOQ;
  pos = dns_packet_copy(buf,len,pos,qtype,2); if (!pos) goto NOQ;
  pos = dns_packet_copy(buf,len,pos,qclass,2); if (!pos) goto NOQ;

  if (!response_query(q,qtype,qclass)) goto NOQ;
  response_id(header);
  if (byte_equal(qclass,2,DNS_C_IN))
    response[2] |= 4;
  else
    if (byte_diff(qclass,2,DNS_C_ANY)) goto WEIRDCLASS;
  response[3] &= ~128;
  if (!(header[2] & 1)) response[2] &= ~1;

  if (header[2] & 126) goto NOTIMP;
  if (byte_equal(qtype,2,DNS_T_AXFR)) goto NOTIMP;

  case_lowerb(q,dns_domain_length(q));


  if (!respond(q,qtype,ip)) {
    qlog(ip,port,header,q,qtype," - ");
    return 0;
  }
  qlog(ip,port,header,q,qtype," + ");
  return 1;

  NOTIMP:
  response[3] &= ~15;
  response[3] |= 4;
  qlog(ip,port,header,q,qtype," I ");
  return 1;

  WEIRDCLASS:
  response[3] &= ~15;
  response[3] |= 1;
  qlog(ip,port,header,q,qtype," C ");
  return 1;

  NOQ:
  qlog(ip,port,"\0\0","","\0\0"," / ");
  return 0;
}

unsigned short liport;

int main()
{
  char *x;
  int udp53;
  int tcp53;
  int evfd;
  unsigned long buflen;

  struct epoll_event fired_events[EVQUE_LEN];
  struct epoll_event evnet = {
    .events = EPOLLIN,
    .data = { .fd = -1 }
  };
  struct epoll_event accept_event = {
    .events = EPOLLIN | EPOLLONESHOT,
    .data = { .fd = -1 }
  };
  x = env_get("IP");
  if (!x)
    strerr_die2x(111,fatal,"$IP not set");
  if (!ip4_scan(x,ip))
    strerr_die3x(111,fatal,"unable to parse IP address ",x);

  x = env_get("PORT");
  if (!x)
      strerr_die2x(111,fatal,"$PORT not set");
  if (!scan_ushort(x, &liport)) strerr_die3x(111,fatal,"unable to parse PORT number", x);
  x = env_get("BUFLEN");
  if (!x)
      strerr_die2x(111,fatal,"$BUFLEN not set");
  if (!scan_ulong(x, &buflen)) strerr_die3x(111,fatal,"unable to parse BUFLEN number", x);
        
  udp53 = socket_udp();
  if (udp53 == -1)
    strerr_die2sys(111,fatal,"unable to create UDP socket: ");
  if (socket_bind4_reuse(udp53,ip,liport) == -1)
    strerr_die2sys(111,fatal,"unable to bind UDP socket: ");

  tcp53 = socket_tcp();
  if (udp53 == -1)
    strerr_die2sys(111,fatal,"unable to create TCP socket: ");
  if (socket_bind4_reuse(tcp53,ip,liport) == -1)
    strerr_die2sys(111,fatal,"unable to bind UDP socket: ");
  if (listen(tcp53, 8192) == -1) 
    strerr_die2sys(111,fatal,"unable to listen for tcp connections: ");
  droproot(fatal);

  initialize();
  
  //ndelay_off(udp53);
  //ndelay_off(tcp53); keep tcp listen socket unblocked
  socket_tryreservein(udp53,buflen);
  socket_tryreservein(tcp53,buflen);
  socket_tryreserveout(udp53,buflen);
  socket_tryreserveout(tcp53,buflen);
  evfd = epoll_create(1);
  evnet.data.fd = udp53;
  epoll_ctl(evfd, EPOLL_CTL_ADD, udp53, &evnet);
  evnet.data.fd = tcp53;
  epoll_ctl(evfd, EPOLL_CTL_ADD, tcp53, &evnet);
  buffer_putsflush(buffer_2,starting);
  if (!dataini()) strerr_die2sys(111,fatal,"unable to init data: ");
  dbger("data initialized!\n");
  int rc;
  int i;
  int evfs = -1;
  int nfd = -1;
  struct sockaddr_in tcpc;
  socklen_t sclen;

  while (1) {
    //printf("wait for events\n");
    rc = epoll_wait(evfd, fired_events, EVQUE_LEN, -1);
    for(i = 0; i < rc; i++) {
      if (fired_events[i].data.fd == udp53) {
        len = socket_recv4(udp53,buf,sizeof buf,ip,&port);
        if (len < 0) continue;
        if (!doit() ) continue;
        if (response_len > 512) response_tc();
        socket_send4(udp53, response, response_len, ip, port);
        continue;
      }
      if (fired_events[i].data.fd == tcp53) {
        while(1) {
          nfd = accept(tcp53, (struct sockaddr *)&tcpc, &sclen);
          if (nfd == -1) break;
          accept_event.data.fd = nfd;
          epoll_ctl(evfd, EPOLL_CTL_ADD, nfd, &accept_event);
          //printf("tcp_accept: sk = %d\n", nfd);
        }
        continue;
      }
      //printf("dont see this\n");
      if (fired_events[i].data.fd == evfs) {
        //printf("WTF WTF\n");
        continue;
      }
      //the rest are tcp data reads
      len = socket_recv4_tcp(fired_events[i].data.fd, buf, sizeof buf, fired_events[i].events);
      //printf("len=%d\n", len);

      if ( (len < 0) || (getpeername(fired_events[i].data.fd, (struct sockaddr *)&tcpc, &sclen) == -1) ) {
        close(fired_events[i].data.fd);
        continue;
      }
      byte_copy(ip,4,(char *) &tcpc.sin_addr);
      if (!doit()) {
        close(fired_events[i].data.fd);
        continue;
      }
      socket_send4_tcp(fired_events[i].data.fd, response, response_len);
      close(fired_events[i].data.fd);
    }
  }
}
