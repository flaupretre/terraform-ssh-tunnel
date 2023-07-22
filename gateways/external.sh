# AWS external Gateway
#
# Source an external script
#----------------------------------------------------------------------------

if [ -f "$EXTERNAL_SCRIPT" ]; then
  . "$EXTERNAL_SCRIPT"
else
  echo "$EXTERNAL_SCRIPT: file not found"
  exit 1
fi
