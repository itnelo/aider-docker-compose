#!/usr/bin/env sh

if [ "$LOCAL_PORT" = "_" ]; then
    LOCAL_PORT=$REMOTE_PORT
fi

SSH_TUNNEL_CMD="
    ssh \
        -v \
        -o StrictHostKeyChecking=no \
        -o ForwardAgent=yes \
        -o TCPKeepAlive=yes \
        -o ConnectTimeout=5 \
        -o ServerAliveCountMax=10 \
        -o ServerAliveInterval=15 \
        -i /root/ssh-import/id_rsa \
        -p $SSH_TUNNEL_PORT \
        -L $LOCAL_HOST:$LOCAL_PORT:$REMOTE_HOST:$REMOTE_PORT \
        $SSH_TUNNEL_USER@$SSH_TUNNEL_HOST \
        -N
"

echo "Running:" ${SSH_TUNNEL_CMD}

${SSH_TUNNEL_CMD}
