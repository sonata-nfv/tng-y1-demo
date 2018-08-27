FROM ubuntu
LABEL maintainer="AR, ALB"
RUN apt-get update
RUN apt-get install -y telnet \
                       && apt-get remove --purge --auto-remove \
                       && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ADD entrypoint.sh /app
RUN ["chmod", "+x", "/app/entrypoint.sh"]
ENTRYPOINT [ "/app/entrypoint.sh" ]
