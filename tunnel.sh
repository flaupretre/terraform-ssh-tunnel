
# DEBUG=y

MPID="$1"

#---

if [ -z "$MPID" ] ; then
  ABSPATH=$(cd "$(dirname "$0")"; pwd -P)

  query="`dd 2>/dev/null`"
  #echo "query: <$query>" >&2

  export TIMEOUT="`echo $query | sed -e 's/^.*\"timeout\": *\"//' -e 's/\".*$//g'`"
  export SSH_CMD="`echo $query | sed -e 's/^.*\"ssh_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g'`"
  export LOCAL_HOST="`echo $query | sed -e 's/^.*\"local_host\": *\"//' -e 's/\".*$//g'`"
  export LOCAL_PORT="`echo $query | sed -e 's/^.*\"local_port\": *\"//' -e 's/\".*$//g'`"
  export TARGET_HOST="`echo $query | sed -e 's/^.*\"target_host\": *\"//' -e 's/\".*$//g'`"
  export TARGET_PORT="`echo $query | sed -e 's/^.*\"target_port\": *\"//' -e 's/\".*$//g'`"
  export GATEWAY_HOST="`echo $query | sed -e 's/^.*\"gateway_host\": *\"//' -e 's/\".*$//g'`"
  export GATEWAY_PORT="`echo $query | sed -e 's/^.*\"gateway_port\": *\"//' -e 's/\".*$//g'`"
  export SHELL_CMD="`echo $query | sed -e 's/^.*\"shell_cmd\": *\"//' -e 's/\",.*$//g' -e 's/\\\"/\"/g'`"

  if [ -n "$DEBUG" ] ; then
    exec 2>/tmp/t1
    set -x
    env >&2
  fi
  echo "{ \"host\": \"$LOCAL_HOST\" }"
  p=`ps -p $PPID -o "ppid="`
  nohup timeout $TIMEOUT $SHELL_CMD "$ABSPATH/tunnel.sh" $p <&- >&- 2>&- &
  # A little time for the SSH tunnel process to start
  sleep 2
else
  #------ Child
  if [ -n "$DEBUG" ] ; then
    exec 2>/tmp/t2
    set -x
    env >&2
  fi

  $SSH_CMD -N -L $LOCAL_PORT:$TARGET_HOST:$TARGET_PORT -p $GATEWAY_PORT $GATEWAY_HOST &
  CPID=$!

  while true ; do
    if ! ps -p $MPID &>/dev/null; then
      break
    fi
    sleep 5
  done

  kill $CPID
fi

exit 0
