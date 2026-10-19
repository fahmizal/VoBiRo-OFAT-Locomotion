#include <webots/Supervisor.hpp>
#include <winsock2.h>
#include <cstring>
#include <iostream>
int main() {
  webots::Supervisor robot;
  WSADATA data; WSAStartup(MAKEWORD(2,2), &data);
  SOCKET sock=socket(AF_INET,SOCK_DGRAM,0);
  bool standby=false,line=false,stop=false;
  auto command=[&](const char *message) {
    for (int port: {12011,12012}) {
      sockaddr_in dest{};dest.sin_family=AF_INET;dest.sin_port=htons(port);dest.sin_addr.s_addr=inet_addr("127.0.0.1");
      sendto(sock,message,static_cast<int>(strlen(message)),0,reinterpret_cast<sockaddr*>(&dest),sizeof(dest));
    }
    std::cout << "COMPARE_TEST " << robot.getTime() << " " << message << std::endl;
  };
  while(robot.step(static_cast<int>(robot.getBasicTimeStep()))!=-1) {
    double t=robot.getTime();
    if(t>=2 && !standby){command("CMD:INIT");standby=true;}
    if(t>=4 && !line){command("CMD:LINE");line=true;}
    if(t>=16 && !stop){command("CMD:STOP");stop=true;}
    if(t>=18){closesocket(sock);WSACleanup();robot.simulationQuit(0);break;}
  }
  return 0;
}