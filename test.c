#include <sys/socket.h>
#include <netinet/in.h>
#include <printf.h>
#include <sys/wait.h>

int main(int argc, char const *argv[])
{

    struct in_addr hostIP;
    hostIP.s_addr = INADDR_ANY;

    struct sockaddr_in address;
    address.sin_family = AF_INET;
    address.sin_addr = hostIP;
    address.sin_port = 8080;

    

    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (bind(sockfd, (struct sockaddr_in*) &address, sizeof(address)) == -1)
    {
        printf("Error binding socket.\n");
    }

    return 0;
}
