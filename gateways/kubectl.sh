# K8S kubectl port forwarding
#
# Parameters :
#   GATEWAY_HOST: a string usable as port forwarding target (pod/xxx, service/xxx, deployment/xxx...)
#   KUBECTL_CMD: Alternate command to run kubectl (default: 'kubectl')
#   KUBECTL_CONTEXT: Context name (as defined in kubectl config file, default: current context)
#   KUBECTL_NAMESPACE: Kubernetes namespace (default: current namespace)
#   KUBECTL_OPTIONS: Other options (default: empty)
#----------------------------------------------------------------------------

opts="$KUBECTL_OPTIONS"
[ -n "$KUBECTL_CONTEXT" ] && opts="$opts --context=$KUBECTL_CONTEXT"
[ -n "$KUBECTL_NAMESPACE" ] && opts="$opts --namespace=$KUBECTL_NAMESPACE"

$KUBECTL_CMD port-forward $opts "$GATEWAY_HOST" $LOCAL_PORT:$TARGET_PORT &

CPID=$!
