
used_ports=" "
for p in $(ss -Htan | awk '{print $4}' | cut -d':' -f2 | sort -u) ; do
  used_ports="$used_ports$p "
done

port=$(seq 20000 30000 | shuf | head -1)
while true; do
  echo "$used_ports" | grep " port " >/dev/null  || break
  port=$(( "$port" + 1 ))
done

echo "{\"port\": \"$port\"}"
