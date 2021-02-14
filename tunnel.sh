
TIMEOUT="$1"
SSH="$2"
LOCAL_PORT="$3"
TARGET_HOST="$4"
TARGET_PORT="$5"
GATEWAY="$6"
SHELL="$7"
MPID="$8"

if [ -z "$MPID" ] ; then
  echo '{}'
  p=`ps --pid $PPID -o ppid --no-headers`
  nohup timeout $TIMEOUT bash $PWD/$0 $@ $p <&- >&- 2>&- &
  exit 0
fi

$SSH -N -L $LOCAL_PORT:$TARGET_HOST:$TARGET_PORT $GATEWAY &
CPID=$!

while true ; do
  [ -d /proc/$MPID ] || break
  sleep 5
done

kill $CPID

exit 0
