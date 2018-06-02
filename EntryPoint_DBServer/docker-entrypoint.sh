#!/bin/sh
echo "Starting Services"
rm //var/run/avahi-daemon/pid || true
/etc/init.d/dbus start
until [ -e /var/run/dbus/system_bus_socket ]; do
    /usr/bin/logger  "dbus-daemon is not running on hosting server..."
    echo "dbus-daemon is not running on hosting server..."
    sleep 1s
done
/etc/init.d/nginx start
#/etc/init.d/avahi-daemon start
exec avahi-daemon --no-chroot &
cd DBServer
echo "Starting Index Service"
rake ts:start
echo "Starting DBServer"
god start docbox -c docbox.god.rb -D
echo "Starting Service: DONE"
sleep infinity
