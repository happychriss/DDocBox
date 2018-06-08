#!/bin/sh
echo "Starting Services DBDaemon"
rm //var/run/avahi-daemon/pid || true
/etc/init.d/dbus start
until [ -e /var/run/dbus/system_bus_socket ]; do
    /usr/bin/logger  "dbus-daemon is not running on hosting server..."
    echo "dbus-daemon is not running on hosting server..."
    sleep 1s
done
exec avahi-daemon --no-chroot &
echo "Starting DBDaemons"
cd DBDaemon
god start docbox -c docbox.god.rb -D --log ./log/god_dbdaemon.log
set -e
sleep infinity