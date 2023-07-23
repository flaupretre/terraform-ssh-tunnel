
TUNNEL_TF_PID="$1"
ret=0

#---

if [ -z "$TUNNEL_TF_PID" ] ; then
  if [ -n "$TUNNEL_DEBUG" ] ; then
    exec 2>/tmp/t1.$$
    set -x
    env >&2
  fi

  TUNNEL_ABSPATH=$(cd "$(dirname "$0")"; pwd -P)
  export TUNNEL_ABSPATH

  query="$(dd 2>/dev/null)"
  [ -n "$TUNNEL_DEBUG" ] && echo "query: <$query>" >&2

  TUNNEL_CREATE="$(echo "$query" | sed -e 's/^.*\"create\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_CREATE
  TUNNEL_ENV="$(echo "$query" | sed -e 's/^.*\"env\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_ENV
  TUNNEL_EXTERNAL_SCRIPT="$(echo "$query" | sed -e 's/^.*\"external_script\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_EXTERNAL_SCRIPT
  TUNNEL_GATEWAY_HOST="$(echo "$query" | sed -e 's/^.*\"gateway_host\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_GATEWAY_HOST
  TUNNEL_GATEWAY_PORT="$(echo "$query" | sed -e 's/^.*\"gateway_port\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_GATEWAY_PORT
  TUNNEL_GATEWAY_USER="$(echo "$query" | sed -e 's/^.*\"gateway_user\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_GATEWAY_USER
  TUNNEL_KUBECTL_CMD="$(echo "$query" | sed -e 's/^.*\"kubectl_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_KUBECTL_CMD
  TUNNEL_KUBECTL_CONTEXT="$(echo "$query" | sed -e 's/^.*\"kubectl_context\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_KUBECTL_CONTEXT
  TUNNEL_KUBECTL_NAMESPACE="$(echo "$query" | sed -e 's/^.*\"kubectl_namespace\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_KUBECTL_NAMESPACE
  TUNNEL_LOCAL_HOST="$(echo "$query" | sed -e 's/^.*\"local_host\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_LOCAL_HOST
  TUNNEL_LOCAL_PORT="$(echo "$query" | sed -e 's/^.*\"local_port\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_LOCAL_PORT
  TUNNEL_PARENT_WAIT_SLEEP="$(echo "$query" | sed -e 's/^.*\"parent_wait_sleep\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_PARENT_WAIT_SLEEP
  TUNNEL_SHELL_CMD="$(echo "$query" | sed -e 's/^.*\"shell_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_SHELL_CMD
  TUNNEL_SSH_CMD="$(echo "$query" | sed -e 's/^.*\"ssh_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_SSH_CMD
  TUNNEL_SSM_DOCUMENT_NAME="$(echo "$query" | sed -e 's/^.*\"ssm_document_name\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_SSM_DOCUMENT_NAME
  TUNNEL_SSM_OPTIONS="$(echo "$query" | sed -e 's/^.*\"ssm_options\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_SSM_OPTIONS
  TUNNEL_TARGET_HOST="$(echo "$query" | sed -e 's/^.*\"target_host\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_TARGET_HOST
  TUNNEL_TARGET_PORT="$(echo "$query" | sed -e 's/^.*\"target_port\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_TARGET_PORT
  TUNNEL_TIMEOUT="$(echo "$query" | sed -e 's/^.*\"timeout\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_TIMEOUT
  TUNNEL_CHECK_SLEEP="$(echo "$query" | sed -e 's/^.*\"tunnel_check_sleep\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_CHECK_SLEEP
  TUNNEL_TYPE="$(echo "$query" | sed -e 's/^.*\"type\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_TYPE

  # Set AWS_PROFILE only if var is not empty
  profile="$(echo "$query" | sed -e 's/^.*\"aws_profile\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  if [ -n "$profile" ] ; then
    AWS_PROFILE="$profile"
    export AWS_PROFILE
  fi

  if [ "X$TUNNEL_CREATE" = X -o "X$TUNNEL_GATEWAY_HOST" = X ] ; then
    # No tunnel - connect directly to target host
    do_tunnel=''
    cnx_host="$TUNNEL_TARGET_HOST"
    cnx_port="$TUNNEL_TARGET_PORT"
  else
    do_tunnel='y'
    cnx_host="$TUNNEL_LOCAL_HOST"
    cnx_port="$TUNNEL_LOCAL_PORT"
  fi

  echo "{ \"host\": \"$cnx_host\",  \"port\": \"$cnx_port\" }"

  if [ -n "$do_tunnel" ] ; then
    if [ "$(readlink /bin/ls)" = "/bin/busybox" ]; then
        p=$PPID
    else
        p=$(ps p $PPID -o "ppid=")
    fi
    clog=$(mktemp)
    nohup timeout "$TUNNEL_TIMEOUT" "$TUNNEL_SHELL_CMD" "$TUNNEL_ABSPATH/tunnel.sh" "$p" <&- >&- 2>"$clog" &
    TUNNEL_CHILD_PID=$!
    # A little time for the SSH tunnel process to start or fail
    sleep "$TUNNEL_PARENT_WAIT_SLEEP"
    # If the child process does not exist anymore after this delay, report failure
    if ! ps -p "$TUNNEL_CHILD_PID" >/dev/null 2>&1 ; then
      echo "Child process ($TUNNEL_CHILD_PID) failure - Aborting" >&2
      echo "Child diagnostics follow:" >&2
      cat "$clog" >&2
      rm -f "$clog"
      ret=1
    fi
    rm -f "$clog"
  fi
else
  #------ Child
  if [ -n "$TUNNEL_DEBUG" ] ; then
    exec 2>/tmp/t2.$$
    set -x
    env >&2
  fi

  TUNNEL_PID=""
  TUNNEL_TODELETE=""

  script="$TUNNEL_ABSPATH/gateways/$TUNNEL_TYPE.sh"
  if [ ! -f "$script" ]; then
    echo "$script: file not found"
  fi

  if [ -n "$TUNNEL_ENV" ]; then
    eval "$TUNNEL_ENV"
  fi

  # Script must set $TUNNEL_PID
  . "$script"

  sleep "$TUNNEL_CHECK_SLEEP"

  while true ; do
    if ! ps -p "$TUNNEL_PID" >/dev/null 2>&1 ; then
      echo "SSH process ($TUNNEL_PID) failure - Aborting" >&2
      [ -n "$TUNNEL_TODELETE" ] && /bin/rm -rf $TUNNEL_TODELETE
      exit 1
    fi
    ps -p "$TUNNEL_TF_PID" >/dev/null 2>&1 || break
    sleep 1
  done

  kill $TUNNEL_PID
  [ -n "$TUNNEL_TODELETE" ] && /bin/rm -rf $TUNNEL_TODELETE
fi

exit $ret
