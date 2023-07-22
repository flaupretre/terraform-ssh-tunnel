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

gw="$GATEWAY_HOST"
[ "X$GATEWAY_USER" = X ] || gw="$GATEWAY_USER@$GATEWAY_HOST"

$GCLOUD_CMD compute ssh \
  --tunnel-through-iap \
  --ssh-key-expire-after "$TIMEOUT" \
  --ssh-flag="-N -L $LOCAL_HOST:$LOCAL_PORT:$TARGET_HOST:$TARGET_PORT -p $GATEWAY_PORT" \
  "$gw" &

CPID=$!
