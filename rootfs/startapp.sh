#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

cd /config
exec /opt/betterbird/betterbird -purgecaches -profile /config/profile >> /config/log/betterbird/output.log 2>> /config/log/betterbird/error.log

# vim:ft=sh:ts=4:sw=4:et:sts=4
