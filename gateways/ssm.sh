# AWS SSM Gateway
# Here, we open an SSH tunnel through an EC2 instance available to SSM session
# management. The EC2 instance does not need to have a public address as
# connection is done through the AWS API.
#
#----------------------------------------------------------------------------

gw="$TUNNEL_GATEWAY_HOST"
[ "X$TUNNEL_GATEWAY_USER" = X ] || gw="$TUNNEL_GATEWAY_USER@$TUNNEL_GATEWAY_HOST"


# If AWS_ASSUME_ROLE is not empty, execute the assume-role command and
# set the environment variables
if [ -n "$AWS_ASSUME_ROLE" ] ; then
  eval "$(aws sts assume-role --role-arn "$AWS_ASSUME_ROLE" --role-session-name="terraform-ssh-tunnel" --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text | awk '{ print "export AWS_ACCESS_KEY_ID=" $1 "\nexport AWS_SECRET_ACCESS_KEY=" $2 "\nexport AWS_SESSION_TOKEN=" $3 }')"
fi

if [ "$TUNNEL_SSM_DOCUMENT_NAME" == "AWS-StartPortForwardingSessionToRemoteHost" ]; then
aws ssm start-session --target $TUNNEL_GATEWAY_HOST \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters "{\"portNumber\":[\"$TUNNEL_TARGET_PORT\"],\"localPortNumber\":[\"$TUNNEL_LOCAL_PORT\"], \"host\":[\"$TUNNEL_TARGET_HOST\"]}" &

elif ["$TUNNEL_SSM_DOCUMENT_NAME" == "AWS-StartSSHSession"]; then
$TUNNEL_SSH_CMD \
  -o ProxyCommand="aws ssm start-session $TUNNEL_SSM_OPTIONS --target %h --document-name $TUNNEL_SSM_DOCUMENT_NAME --parameters 'portNumber=%p'" \
  -N \
  -L "$TUNNEL_LOCAL_HOST:$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_HOST:$TUNNEL_TARGET_PORT" \
  -p "$TUNNEL_GATEWAY_PORT" \
   "$gw" &
fi
TUNNEL_PID=$!
