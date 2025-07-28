# Google IAP Gateway
#----------------------------------------------------------------------------

# prevent connection error 'Login profile size exceeds 32 KiB'
# https://github.com/kyma-project/test-infra/issues/93#issuecomment-457263589
account=`echo $($TUNNEL_GCLOUD_CMD config list account --format "value(core.account)")`

for key in $($TUNNEL_GCLOUD_CMD compute os-login ssh-keys list | grep -v FINGERPRINT); do
    echo "SSH key '$key' for account '$account' removed"
    $TUNNEL_GCLOUD_CMD compute os-login ssh-keys remove --key "$key"
done

gw="$TUNNEL_GATEWAY_HOST"
[ "X$TUNNEL_GATEWAY_USER" = X ] || gw="$TUNNEL_GATEWAY_USER@$TUNNEL_GATEWAY_HOST"

project=""
[ "X$TUNNEL_IAP_PROJECT" = X ] || project="--project $TUNNEL_IAP_PROJECT"

zone=""
[ "X$TUNNEL_IAP_ZONE" = X ] || zone="--zone $TUNNEL_IAP_ZONE"

$TUNNEL_GCLOUD_CMD compute ssh -q \
  --tunnel-through-iap \
  --ssh-key-expire-after "$TUNNEL_TIMEOUT" \
  --ssh-flag="-N -L $TUNNEL_LOCAL_HOST:$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_HOST:$TUNNEL_TARGET_PORT" \
  $project \
  $zone \
  $gw &

TUNNEL_PID=$!
