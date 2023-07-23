# K8S kubectl port forwarding
#
#----------------------------------------------------------------------------

cmd="$TUNNEL_KUBECTL_CMD"
[ -n "$TUNNEL_KUBECTL_CONTEXT" ] && cmd="$cmd --context=$TUNNEL_KUBECTL_CONTEXT"
[ -n "$TUNNEL_KUBECTL_NAMESPACE" ] && cmd="$cmd --namespace=$TUNNEL_KUBECTL_NAMESPACE"

$cmd port-forward "$TUNNEL_GATEWAY_HOST" "$TUNNEL_LOCAL_PORT:$TUNNEL_TARGET_PORT" &

TUNNEL_PID=$!
