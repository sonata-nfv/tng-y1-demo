FROM debian:stretch
LABEL maintainer="Felipe Vicens felipevicens@atos.net"
RUN apt-get update
RUN apt-get install -y build-essential \
                       libssl-dev \
                       git \
                       zlib1g \
                       zlib1g-dev \
                       && apt-get remove --purge --auto-remove \
                       && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN git clone https://github.com/giltene/wrk2.git
WORKDIR /app/wrk2
RUN make

FROM debian:stretch
LABEL maintainer="Felipe Vicens felipevicens@atos.net"
RUN apt-get update && \
    apt-get install -y libssl-dev \
                       jq \
		       netcat-openbsd \
                       && rm -rf /var/lib/apt/lists/*
COPY --from=0 /app/wrk2/wrk /usr/local/bin/
ADD result.lua /app/
ADD result_proxy.lua /app/
ADD entrypoint.sh /app/
ENTRYPOINT [ "/app/entrypoint.sh" ]
