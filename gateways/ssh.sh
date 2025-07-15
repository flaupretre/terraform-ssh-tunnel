# Default (SSH) gateway

gw="$TUNNEL_GATEWAY_HOST"
[ "X$TUNNEL_GATEWAY_USER" = X ] || gw="$TUNNEL_GATEWAY_USER@$TUNNEL_GATEWAY_HOST"

if [ -n "$TUNNEL_SSH_PRIVATE_KEY" ]; then
  echo "Adding private key to ssh-agent..." >&2
  echo "${TUNNEL_SSH_PRIVATE_KEY}" | ssh-add -
  trap 'echo "Removing private key from ssh-agent..." >&2; ssh-add -d <<< "${TUNNEL_SSH_PRIVATE_KEY}"' EXIT
fi

$TUNNEL_SSH_CMD \
  -N \
  -L "$TUNNEL_LOCAL_HOST:$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_HOST:$TUNNEL_TARGET_PORT" \
  -p "$TUNNEL_GATEWAY_PORT" \
  "$gw" &

TUNNEL_PID=$!
