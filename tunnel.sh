
MPID="$1"
ret=0

#---

if [ -z "$MPID" ] ; then
  if [ -n "$TUNNEL_DEBUG" ] ; then
    set -x
    env >&2
  fi

  ABSPATH=$(cd "$(dirname "$0")"; pwd -P)

  query="`dd 2>/dev/null`"
  [ -n "$TUNNEL_DEBUG" ] && echo "query: <$query>" >&2

  export TIMEOUT="`echo $query | sed -e 's/^.*\"timeout\": *\"//' -e 's/\".*$//g'`"
  export SSH_CMD="`echo $query | sed -e 's/^.*\"ssh_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g'`"
  export LOCAL_HOST="`echo $query | sed -e 's/^.*\"local_host\": *\"//' -e 's/\".*$//g'`"
  export LOCAL_PORT="`echo $query | sed -e 's/^.*\"local_port\": *\"//' -e 's/\".*$//g'`"
  export TARGET_HOST="`echo $query | sed -e 's/^.*\"target_host\": *\"//' -e 's/\".*$//g'`"
  export TARGET_PORT="`echo $query | sed -e 's/^.*\"target_port\": *\"//' -e 's/\".*$//g'`"
  export GATEWAY_HOST="`echo $query | sed -e 's/^.*\"gateway_host\": *\"//' -e 's/\".*$//g'`"
  export GATEWAY_PORT="`echo $query | sed -e 's/^.*\"gateway_port\": *\"//' -e 's/\".*$//g'`"
  export SHELL_CMD="`echo $query | sed -e 's/^.*\"shell_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g'`"
  export SSH_TUNNEL_CHECK_SLEEP="`echo $query | sed -e 's/^.*\"ssh_tunnel_check_sleep\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g'`"

  echo "{ \"host\": \"$LOCAL_HOST\" }"
  p=`ps -p $PPID -o "ppid="`
  clog=`mktemp`
  nohup timeout $TIMEOUT $SHELL_CMD "$ABSPATH/tunnel.sh" $p <&- >&- 2>$clog &
  CPID=$!
  # A little time for the SSH tunnel process to start or fail
  sleep 3
  # If the child process does not exist anymore after this delay, report failure
  if ! ps -p $CPID >/dev/null 2>&1 ; then
    echo "Child process ($CPID) failure - Aborting" >&2
    echo "Child diagnostics follow:" >&2
    cat $clog >&2
    rm -f $clog
    ret=1
  fi
  rm -f $clog
else
  #------ Child
  if [ -n "$TUNNEL_DEBUG" ] ; then
    set -x
    env >&2
  fi

  $SSH_CMD -N -L localhost:$LOCAL_PORT:$TARGET_HOST:$TARGET_PORT -p $GATEWAY_PORT $GATEWAY_HOST &
  CPID=$!
  
  sleep $SSH_TUNNEL_CHECK_SLEEP

  while true ; do
    if ! ps -p $CPID >/dev/null 2>&1 ; then
      echo "SSH process ($CPID) failure - Aborting" >&2
      exit 1
    fi
    ps -p $MPID >/dev/null 2>&1 || break
    sleep 1
  done

  kill $CPID
fi

exit $ret
