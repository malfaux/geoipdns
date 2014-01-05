#include <sys/types.h>
#include <sys/param.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include "byte.h"
#include "socket.h"

int socket_send4_tcp(int s, const char *buf, int len)
{
    struct iovec iov[2];
    char len_[2];
    int iovcnt;
    uint16_pack_big(len_, (unsigned short)len);
    iov[0].iov_base = len_;
    iov[0].iov_len = 2;
    iov[1].iov_base = buf;
    iov[1].iov_len = len;
    iovcnt = sizeof(iov) / sizeof(struct iovec);
    return writev(s, iov, iovcnt);
}
int socket_send4(int s,const char *buf,int len,const char ip[4],uint16 port)
{
  struct sockaddr_in sa;

  byte_zero(&sa,sizeof sa);
  sa.sin_family = AF_INET;
  uint16_pack_big((char *) &sa.sin_port,port);
  byte_copy((char *) &sa.sin_addr,4,ip);

  return sendto(s,buf,len,0,(struct sockaddr *) &sa,sizeof sa);
}

