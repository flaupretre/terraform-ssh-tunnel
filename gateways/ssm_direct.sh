aws ssm start-session \
    --target $TUNNEL_GATEWAY_HOST \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters "{\"host\":[\"$TUNNEL_TARGET_HOST\"], \"portNumber\":[\"$TUNNEL_TARGET_PORT\"], \"localPortNumber\":[\"$TUNNEL_LOCAL_PORT\"]}" &
TUNNEL_PID=$!
