
TUNNEL_TF_PID="$1"
ret=0

#---

ps_is_busybox()
{
test -h /bin/ps || return 1
[ "$(readlink /bin/ps)" = "/bin/busybox" ]
}

#---

function get_root_pid()
{
  local ppid gppid
  if ps_is_busybox; then
    # For BusyBox 'ps' (e.g., Alpine Linux)
    # Retrieve the parent PID (ppid) of the current shell
    ppid=$(ps -o pid,ppid | awk -v pid="$$" '$1 == pid { print $2 }')
    # Retrieve the grandparent PID (GPPID) using the PPID
    gppid=$(ps -o pid,ppid | awk -v pid="$ppid" '$1 == pid { print $2 }')
  else
    # For GNU 'ps'
    # Retrieve the parent PID (ppid) of the current shell
    ppid=$(ps -o ppid= -p $$)
    # Retrieve the grandparent PID (gppid) using the PPID
    gppid=$(ps -o ppid= -p "$ppid")
  fi

  echo $gppid
}

#---

process_is_up()
{
  local pid ret

  pid="$1"
  if ps_is_busybox ; then
    ps -o pid | awk '{ print $1 }' | grep "^$pid\$" >/dev/null 2>&1
    ret=$?
  else
    ps -p "$pid" >/dev/null 2>&1
    ret=$?
  fi

  return $ret
}

#---

if [ -z "$TUNNEL_TF_PID" ] ; then
  if [ -n "$TUNNEL_DEBUG" ] ; then
    exec 2>/tmp/t1.$$
    set -x
    env >&2
  fi

  TUNNEL_ABSPATH=$(cd "$(dirname "$0")" >/dev/null; pwd -P)
  export TUNNEL_ABSPATH

  query="$(dd 2>/dev/null)"
  [ -n "$TUNNEL_DEBUG" ] && echo "query: <$query>" >&2

  TUNNEL_CREATE="$(echo "$query" | sed -e 's/^.*\"create\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_CREATE
  TUNNEL_TYPE="$(echo "$query" | sed -e 's/^.*\"type\": *\"//' -e 's/\".*$//g')"
  export TUNNEL_TYPE
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
  TUNNEL_IAP_PROJECT="$(echo "$query" | sed -e 's/^.*\"iap_project\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_IAP_PROJECT
  TUNNEL_IAP_ZONE="$(echo "$query" | sed -e 's/^.*\"iap_zone\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_IAP_ZONE
  TUNNEL_GCLOUD_CMD="$(echo "$query" | sed -e 's/^.*\"gcloud_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_GCLOUD_CMD
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
  TUNNEL_SSH_PRIVATE_KEY="$(echo "$query" | sed -e 's/^.*"ssh_private_key": *"//' -e 's/",.*$//' -e 's/\\n/\n/g' -e 's/\\\"/\"/g')"
  export TUNNEL_SSH_PRIVATE_KEY
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
  TUNNEL_SSM_PROFILE="$(echo "$query" | sed -e 's/^.*\"ssm_profile\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_SSM_PROFILE
  TUNNEL_SSM_ROLE="$(echo "$query" | sed -e 's/^.*\"ssm_role\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g')"
  export TUNNEL_SSM_ROLE

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

    p=$(get_root_pid)
    clog=$(mktemp)
    nohup timeout "$TUNNEL_TIMEOUT" "$TUNNEL_SHELL_CMD" "$TUNNEL_ABSPATH/tunnel.sh" "$p" <&- >&- 2>"$clog" &
    TUNNEL_CHILD_PID=$!
    # A little time for the tunnel process to start or fail
    sleep "$TUNNEL_PARENT_WAIT_SLEEP"
    # If the child process does not exist anymore after this delay, report failure
    if ! process_is_up "$TUNNEL_CHILD_PID" ; then
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

  script="$TUNNEL_ABSPATH/gateways/$TUNNEL_TYPE.sh"
  if [ ! -f "$script" ]; then
    echo "$script: file not found"
  fi

  if [ -n "$TUNNEL_ENV" ]; then
    eval "$TUNNEL_ENV"
  fi

  TUNNEL_PID=""
  TUNNEL_TODELETE=""

  # Script must set $TUNNEL_PID
  . "$script"

  sleep "$TUNNEL_CHECK_SLEEP"

  while true ; do
    if ! process_is_up "$TUNNEL_PID" ; then
      echo "Tunnel process ($TUNNEL_PID) failure - Aborting" >&2
      [ -n "$TUNNEL_TODELETE" ] && /bin/rm -rf $TUNNEL_TODELETE
      exit 1
    fi
    process_is_up "$TUNNEL_TF_PID" || break
    sleep 1
  done

  kill "$TUNNEL_PID"
  [ -n "$TUNNEL_TODELETE" ] && /bin/rm -rf $TUNNEL_TODELETE
fi

exit $ret
