# AWS SSM Gateway
# Here, we open an SSH tunnel through an EC2 instance available to SSM session
# management. The EC2 instance does not need to have a public address as
# connection is done through the AWS API.
#
#----------------------------------------------------------------------------

gw="$TUNNEL_GATEWAY_HOST"
[ "X$TUNNEL_GATEWAY_USER" = X ] || gw="$TUNNEL_GATEWAY_USER@$TUNNEL_GATEWAY_HOST"

if [ -n "$TUNNEL_SSM_PROFILE" ] ; then
  AWS_PROFILE="$TUNNEL_SSM_PROFILE"
  export AWS_PROFILE
fi

# If TUNNEL_SSM_ROLE is not empty, execute the assume-role command and
# set the environment variables
if [ -n "$TUNNEL_SSM_ROLE" ] ; then
  eval "$(aws sts assume-role --role-arn "$TUNNEL_SSM_ROLE" --role-session-name="terraform-ssh-tunnel" --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text | awk '{ print "export AWS_ACCESS_KEY_ID=" $1 "\nexport AWS_SECRET_ACCESS_KEY=" $2 "\nexport AWS_SESSION_TOKEN=" $3 }')"
fi


$TUNNEL_SSH_CMD \
  -o ProxyCommand="aws ssm start-session $TUNNEL_SSM_OPTIONS --target %h --document-name $TUNNEL_SSM_DOCUMENT_NAME --parameters 'portNumber=%p'" \
  -N \
  -L "$TUNNEL_LOCAL_HOST:$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_HOST:$TUNNEL_TARGET_PORT" \
  -p "$TUNNEL_GATEWAY_PORT" \
   "$gw" &

TUNNEL_PID=$!
