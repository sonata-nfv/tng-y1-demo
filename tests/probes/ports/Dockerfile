FROM ubuntu
LABEL maintainer="AR, ALB"
RUN apt-get update
RUN apt-get install -y apt-utils \
                       telnet \
                       nmap \
                       && apt-get remove --purge --auto-remove \
                       && rm -rf /var/lib/apt/lists/*
#ENTRYPOINT [ "entrypoint.sh" ]
ENTRYPOINT [ "telnet", "172.31.8.101", "80" ]
