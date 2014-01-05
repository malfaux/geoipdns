#include <sys/types.h>
#include "uint16.h"
#include <sys/param.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include "byte.h"
#include "socket.h"
#include <sys/epoll.h>
#include <sys/uio.h>

int socket_recv4_tcp(int s, char *buf, int len, int events)
{
    unsigned short numbytes;
    struct iovec iov[2];
    int iovcnt;
    char qlen_[2];
    unsigned short qlen;

    iov[0].iov_base = qlen_;
    iov[0].iov_len = 2;
    iov[1].iov_base = buf;
    iov[1].iov_len = len;
    iovcnt = sizeof(iov) / sizeof(struct iovec);

    if (events != EPOLLIN) return -1;

    numbytes = readv(s, iov, iovcnt);
    if(numbytes == -1) return -1;
    //printf("readv: %d bytes read\n", numbytes);
    uint16_unpack_big(qlen_, &qlen);
    if (qlen + 2 != numbytes) return -1;
    return qlen;
}

int socket_recv4(int s,char *buf,int len,char ip[4],uint16 *port)
{
  struct sockaddr_in sa;
  int dummy = sizeof sa;
  int r;

  r = recvfrom(s,buf,len,0,(struct sockaddr *) &sa,&dummy);
  if (r == -1) return -1;

  byte_copy(ip,4,(char *) &sa.sin_addr);
  uint16_unpack_big((char *) &sa.sin_port,port);

  return r;
}
