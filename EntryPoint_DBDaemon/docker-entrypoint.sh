#!/bin/sh
rm //var/run/avahi-daemon/pid || true
/etc/init.d/dbus start
until [ -e /var/run/dbus/system_bus_socket ]; do
    /usr/bin/logger  "dbus-daemon is not running on hosting server..."
    sleep 1s
done
exec avahi-daemon --no-chroot &
set -e
sleep infinity
