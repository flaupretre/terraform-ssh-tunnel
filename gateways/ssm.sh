# AWS SSM Gateway
# Here, we open an SSH tunnel through an EC2 instance available to SSM session
# management. The EC2 instance does not need to have a public address as
# connection is done through the AWS API.
#
#----------------------------------------------------------------------------

gw="$TUNNEL_GATEWAY_HOST"
[ "X$TUNNEL_GATEWAY_USER" = X ] || gw="$TUNNEL_GATEWAY_USER@$TUNNEL_GATEWAY_HOST"

$TUNNEL_SSH_CMD \
  -o ProxyCommand="aws ssm start-session $TUNNEL_SSM_OPTIONS --target %h --document-name $TUNNEL_SSM_DOCUMENT_NAME --parameters 'portNumber=%p'" \
  -N \
  -L "$TUNNEL_LOCAL_HOST:$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_HOST:$TUNNEL_TARGET_PORT" \
  -p "$TUNNEL_GATEWAY_PORT" \
   "$gw" &

TUNNEL_PID=$!
