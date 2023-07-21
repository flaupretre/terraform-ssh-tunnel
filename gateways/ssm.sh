# AWS SSM Gateway
# Here, we open an SSH tunnel through an EC2 instance available to SSM session
# management. The EC2 instance does not need to have a public address as
# connection is done through the AWS API.
#
# Parameters :
#   GATEWAY_HOST: The instance ID of the gateway instance
#----------------------------------------------------------------------------

gw="$GATEWAY_HOST"
[ "X$GATEWAY_USER" = X ] || gw="$GATEWAY_USER@$GATEWAY_HOST"

$SSH_CMD \
  -o ProxyCommand "aws ssm start-session $SSM_OPTIONS --target %h --document-name $SSM_DOCUMENT_NAME --parameters 'portNumber=%p'" \
  -N \
  -L $LOCAL_HOST:$LOCAL_PORT:$TARGET_HOST:$TARGET_PORT \
  -p $GATEWAY_PORT \
   $gw &

CPID=$!
