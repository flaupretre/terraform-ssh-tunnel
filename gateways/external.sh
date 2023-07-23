# AWS external Gateway
#
# Source an external script
#----------------------------------------------------------------------------

if [ -f "$TUNNEL_EXTERNAL_SCRIPT" ]; then
  . "$TUNNEL_EXTERNAL_SCRIPT"
else
  echo "$TUNNEL_EXTERNAL_SCRIPT: file not found"
  exit 1
fi
