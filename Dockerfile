FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app/app .
FROM debian:12-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    dropbear-run \
    tmux \
    net-tools \
    git \
    cmake \
    build-essential \
    ca-certificates \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
WORKDIR /tmp
RUN git clone https://github.com/ambrop72/badvpn.git && \
    cd badvpn && \
    mkdir build && \
    cd build && \
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 && \
    make install && \
    cd / && \
    rm -rf /tmp/badvpn
WORKDIR /
RUN useradd -m -s /bin/bash buhonero && \
    echo 'buhonero:gpc-test' | chpasswd
RUN mkdir -p /etc/dropbear
COPY --from=builder /app/app /usr/local/bin/proxy
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/proxy /usr/local/bin/entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
