# K8S kubectl port forwarding
#
# Parameters :
#   GATEWAY_HOST: a string usable as port forwarding target (pod/xxx, service/xxx, deployment/xxx...)
#   KUBECTL_CMD: Alternate command to run kubectl (default: 'kubectl')
#   KUBECTL_CONTEXT: Context name (as defined in kubectl config file, default: current context)
#   KUBECTL_NAMESPACE: Kubernetes namespace (default: current namespace)
#----------------------------------------------------------------------------

cmd="$KUBECTL_CMD"
[ -n "$KUBECTL_CONTEXT" ] && cmd="$cmd --context=$KUBECTL_CONTEXT"
[ -n "$KUBECTL_NAMESPACE" ] && cmd="$cmd --namespace=$KUBECTL_NAMESPACE"

$cmd port-forward "$GATEWAY_HOST" "$LOCAL_PORT:$TARGET_PORT" &

CPID=$!
