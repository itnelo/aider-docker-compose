
FROM alpine:3.23

LABEL maintainer="Pavel Petrov <itnelo@gmail.com>"
LABEL version="0.1.0"
LABEL description="SSH tunnel for forwarding Ollama port inside docker network"

ENV LOCAL_HOST=*
ENV LOCAL_PORT=_

ENV REMOTE_HOST=127.0.0.1
ENV REMOTE_PORT=_

ENV SSH_TUNNEL_HOST=_
ENV SSH_TUNNEL_PORT=22
ENV SSH_TUNNEL_USER=root

RUN apk add --no-cache openssh-client

COPY docker-ssh-tunnel-cmd.sh /usr/local/bin/docker-ssh-tunnel-cmd.sh
RUN chmod +x /usr/local/bin/docker-ssh-tunnel-cmd.sh

CMD ["docker-ssh-tunnel-cmd.sh"]
