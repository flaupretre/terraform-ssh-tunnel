
port=$(seq 20000 30000 | shuf | head -1)
while true; do
  ss -Htan | awk '{print $4}' | grep ":port$" >/dev/null  || break
  port=$(( "$port" + 1 ))
done

echo "{\"port\": \"$port\"}"
