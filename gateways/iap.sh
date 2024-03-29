# Google IAP Gateway
#
#------WARNING--WARNING--WARNING--WARNING--WARNING--WARNING--WARNING--
#
# The code below is purely EXPERIMENTAL. I wrote it
#  from information I got on the Internet and I could not
#  test it as I don't have access to a GCP platform.
#
# If you have access to a GCP platform and can test this, your return will be
# warmly appreciated.
#----------------------------------------------------------------------------

gw="$TUNNEL_GATEWAY_HOST"
[ "X$TUNNEL_GATEWAY_USER" = X ] || gw="$TUNNEL_GATEWAY_USER@$TUNNEL_GATEWAY_HOST"

$TUNNEL_GCLOUD_CMD compute ssh \
  --tunnel-through-iap \
  --ssh-key-expire-after "$TUNNEL_TIMEOUT" \
  --ssh-flag="-N -L $TUNNEL_LOCAL_HOST:$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_HOST:$TUNNEL_TARGET_PORT -p $TUNNEL_GATEWAY_PORT" \
  "$gw" &

TUNNEL_PID=$!
