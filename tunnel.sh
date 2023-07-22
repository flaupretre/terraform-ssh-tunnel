
MPID="$1"
ret=0

#---

if [ -z "$MPID" ] ; then
  if [ -n "$TUNNEL_DEBUG" ] ; then
    exec 2>/tmp/t1.$$
    set -x
    env >&2
  fi

  ABSPATH=$(cd "$(dirname "$0")"; pwd -P)
  export ABSPATH

  query="$(dd 2>/dev/null)"
  [ -n "$TUNNEL_DEBUG" ] && echo "query: <$query>" >&2

  CREATE="$(echo "$query" | sed -e 's/^.*\"create\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export CREATE
  ENV="$(echo "$query" | sed -e 's/^.*\"env\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export ENV
  EXTERNAL_SCRIPT="$(echo "$query" | sed -e 's/^.*\"external_script\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export EXTERNAL_SCRIPT
  GATEWAY_HOST="$(echo "$query" | sed -e 's/^.*\"gateway_host\": *\"//' -e 's/\".*$//g')"
  export GATEWAY_HOST
  GATEWAY_PORT="$(echo "$query" | sed -e 's/^.*\"gateway_port\": *\"//' -e 's/\".*$//g')"
  export GATEWAY_PORT
  GATEWAY_USER="$(echo "$query" | sed -e 's/^.*\"gateway_user\": *\"//' -e 's/\".*$//g')"
  export GATEWAY_USER
  KUBECTL_CMD="$(echo "$query" | sed -e 's/^.*\"kubectl_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export KUBECTL_CMD
  KUBECTL_CONTEXT="$(echo "$query" | sed -e 's/^.*\"kubectl_context\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export KUBECTL_CONTEXT
  KUBECTL_NAMESPACE="$(echo "$query" | sed -e 's/^.*\"kubectl_namespace\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export KUBECTL_NAMESPACE
  LOCAL_HOST="$(echo "$query" | sed -e 's/^.*\"local_host\": *\"//' -e 's/\".*$//g')"
  export LOCAL_HOST
  LOCAL_PORT="$(echo "$query" | sed -e 's/^.*\"local_port\": *\"//' -e 's/\".*$//g')"
  export LOCAL_PORT
  PARENT_WAIT_SLEEP="$(echo "$query" | sed -e 's/^.*\"parent_wait_sleep\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export PARENT_WAIT_SLEEP
  SHELL_CMD="$(echo "$query" | sed -e 's/^.*\"shell_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export SHELL_CMD
  SSH_CMD="$(echo "$query" | sed -e 's/^.*\"ssh_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export SSH_CMD
  SSM_DOCUMENT_NAME="$(echo "$query" | sed -e 's/^.*\"ssm_document_name\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export SSM_DOCUMENT_NAME
  SSM_OPTIONS="$(echo "$query" | sed -e 's/^.*\"ssm_options\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export SSM_OPTIONS
  TARGET_HOST="$(echo "$query" | sed -e 's/^.*\"target_host\": *\"//' -e 's/\".*$//g')"
  export TARGET_HOST
  TARGET_PORT="$(echo "$query" | sed -e 's/^.*\"target_port\": *\"//' -e 's/\".*$//g')"
  export TARGET_PORT
  TIMEOUT="$(echo "$query" | sed -e 's/^.*\"timeout\": *\"//' -e 's/\".*$//g')"
  export TIMEOUT
  TUNNEL_CHECK_SLEEP="$(echo "$query" | sed -e 's/^.*\"tunnel_check_sleep\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_CHECK_SLEEP
  TYPE="$(echo "$query" | sed -e 's/^.*\"type\": *\"//' -e 's/\".*$//g')"
  export TYPE

  # Set AWS_PROFILE only if var is not empty
  profile="$(echo "$query" | sed -e 's/^.*\"aws_profile\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  if [ -n "$profile" ] ; then
    AWS_PROFILE="$profile"
    export AWS_PROFILE
  fi

  if [ "X$CREATE" = X -o "X$GATEWAY_HOST" = X ] ; then
    # No tunnel - connect directly to target host
    do_tunnel=''
    cnx_host="$TARGET_HOST"
    cnx_port="$TARGET_PORT"
  else
    do_tunnel='y'
    cnx_host="$LOCAL_HOST"
    cnx_port="$LOCAL_PORT"
  fi

  echo "{ \"host\": \"$cnx_host\",  \"port\": \"$cnx_port\" }"

  if [ -n "$do_tunnel" ] ; then
    p=$(ps -p $PPID -o "ppid=")
    clog=$(mktemp)
    nohup timeout "$TIMEOUT" "$SHELL_CMD" "$ABSPATH/tunnel.sh" "$p" <&- >&- 2>"$clog" &
    CPID=$!
    # A little time for the SSH tunnel process to start or fail
    sleep "$PARENT_WAIT_SLEEP"
    # If the child process does not exist anymore after this delay, report failure
    if ! ps -p "$CPID" >/dev/null 2>&1 ; then
      echo "Child process ($CPID) failure - Aborting" >&2
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

  CPID=""
  TODELETE=""

  script="$ABSPATH/gateways/$TYPE.sh"
  if [ ! -f "$script" ]; then
    echo "$script: file not found"
  fi

  if [ -n "$ENV" ]; then
    eval "$ENV"
  fi

  # Script must set $CPID
  . "$script"

  sleep "$TUNNEL_CHECK_SLEEP"

  while true ; do
    if ! ps -p $CPID >/dev/null 2>&1 ; then
      echo "SSH process ($CPID) failure - Aborting" >&2
      [ -n "$TODELETE" ] && /bin/rm -rf $TODELETE
      exit 1
    fi
    ps -p "$MPID" >/dev/null 2>&1 || break
    sleep 1
  done

  kill $CPID
  [ -n "$TODELETE" ] && /bin/rm -rf $TODELETE
fi

exit $ret
