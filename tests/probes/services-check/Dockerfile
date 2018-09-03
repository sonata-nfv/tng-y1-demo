FROM debian
LABEL maintainer="Felipe Vicens felipevicens@atos.net"
RUN apt-get update && \
    apt-get install -y libssl-dev sshpass \
                       && rm -rf /var/lib/apt/lists/*
ADD result.lua /app/
ADD entrypoint.sh /app/
ENTRYPOINT [ "/app/entrypoint.sh" ]
