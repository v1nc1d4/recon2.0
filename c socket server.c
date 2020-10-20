#include <stdio.h>

#include <stdlib.h>

#include <unistd.h>

#include <sys/socket.h>

#include <string.h>

#include <netinet/in.h>

#include <arpa/inet.h>

#include <sys/types.h>

#include "core/main.h"

int main(int argc, char const *argv[]){

	system("clear");	check_args_s(argc);

	banner_server();

	int opt = 1;

	char const *host = argv[1]; // host var

	int const port = atoi(argv[2]); // port var

	// Create socket.

	int sock_fd = socket(AF_INET, SOCK_STREAM, 0);

	// Setting socket to the port no.

	setsockopt(sock_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT, &opt, sizeof(opt));

	struct sockaddr_in saddress;

	saddress.sin_family = AF_INET;

	saddress.sin_addr.s_addr = inet_addr(host);

	saddress.sin_port = htons(port);

	// Binding our socket.

	bind(sock_fd, (struct sockaddr *)&saddress, sizeof(saddress));

	// Listening for the connection.

	listen(sock_fd, 3);

	int addrlen = sizeof(saddress);

	printf("Waiting for connection\n");

	// Accepting client connection.

	int nsocket = accept(sock_fd,(struct sockaddr *)&saddress,(socklen_t*)&addrlen);

	if (nsocket > 0){

		green();

		printf("[~] Client Connected!.\n[~] Waiting for message!.\n");

		reset();

	};

	// while loop for handle our chat.

	while (1){

		char message[1024];

		char buffer[1024] = {0};

		// Getting Message from client.

		int valread = read( nsocket, buffer, 1024);

		yellow();

		printf("[-] client :> %s",buffer ); // Print message in console.

		reset();

		blue();

		printf("[+] server :> ");

		reset();

		fgets(message,1023,stdin);

		// Send your message to client.

		send(nsocket, message, strlen(message), 0);

	}

	

	return 0;

}
