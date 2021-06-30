TIMEOUT="$1"
SSH="$2"
LOCAL_PORT="$3"
TARGET_HOST="$4"
TARGET_PORT="$5"
GATEWAY="$6"
SHELL="$7"
MPID="$8"

ABSPATH=$(cd "$(dirname "$0")"; pwd -P)

if [ -z "$MPID" ] ; then
  echo '{}'
  p=`ps -p $PPID -o "ppid="`
  nohup timeout $TIMEOUT bash "$ABSPATH/tunnel.sh" $@ $p <&- >&- 2>&- &
  # Allow the tunnel to fully establish
  sleep 5
  exit 0
fi

$SSH -N -L $LOCAL_PORT:$TARGET_HOST:$TARGET_PORT $GATEWAY &
CPID=$!

while true ; do
  if ! ps -p $MPID &>/dev/null; then
    break
  fi
  sleep 5
done

kill $CPID

exit 0
