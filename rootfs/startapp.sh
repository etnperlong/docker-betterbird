#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Started as user abc by the labwc/openbox autostart (/defaults/autostart*).
# Kept as a separate script because autostart files are only copied into
# /config on first run, so changes here still reach existing volumes.

mkdir -p /config/log/betterbird /config/profile

# Initialize log files. The session discards application output otherwise.
for LOG_FILE in /config/log/betterbird/output.log /config/log/betterbird/error.log
do
    touch "$LOG_FILE"

    # Make sure the file doesn't grow indefinitely.
    if [ "$(stat -c %s "$LOG_FILE")" -gt 1048576 ]; then
       echo > "$LOG_FILE"
    fi
done

cd /config
exec /opt/betterbird/betterbird -purgecaches -profile /config/profile >> /config/log/betterbird/output.log 2>> /config/log/betterbird/error.log

# vim:ft=sh:ts=4:sw=4:et:sts=4
