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

# prevent connection error 'Login profile size exceeds 32 KiB'
# https://github.com/kyma-project/test-infra/issues/93#issuecomment-457263589
account=`echo $(gcloud config list account --format "value(core.account)")`

for key in $(gcloud compute os-login ssh-keys list | grep -v FINGERPRINT); do
    echo "SSH key '$key' for account '$account' removed"
    gcloud compute os-login ssh-keys remove --key $key
done

gw="$TUNNEL_GATEWAY_HOST"
[ "X$TUNNEL_GATEWAY_USER" = X ] || gw="$TUNNEL_GATEWAY_USER@$TUNNEL_GATEWAY_HOST"

$TUNNEL_SSH_CMD compute ssh -q \
  --tunnel-through-iap \
  --ssh-key-expire-after "$TUNNEL_TIMEOUT" \
  --ssh-flag="-N -L $TUNNEL_LOCAL_HOST:$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_HOST:$TUNNEL_TARGET_PORT" \
  $gw --project $TUNNEL_IAP_GCP_PROJECT --zone $TUNNEL_IAP_GCP_ZONE &

TUNNEL_PID=$!
