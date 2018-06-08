#!/bin/sh
echo "********* Welcome to start script of DocBox on Docker ********"
echo "Starting Avahi Services and DBus Mapping"
rm //var/run/avahi-daemon/pid || true
/etc/init.d/dbus start
until [ -e /var/run/dbus/system_bus_socket ]; do
    /usr/bin/logger  "dbus-daemon is not running on hosting server..."
    echo "dbus-daemon is not running on hosting server..."
    sleep 1s
done

echo "Checking if Database is set-up..takes some time"
#https://github.com/vishnubob/wait-for-it
//init/wait_for_it.sh mysql:3306 --timeout=0
cd DBServer
if rake db:migrate:status>/dev/null 2>&1 ; then
    echo "***** Database exists - continue booting"
else
    echo "****** Assuming fresh installation, creating DB and Index *****"
    rake db:create
    rake db:schema:load
    rake db:seed
    rake ts:configure
    rake assets:precompile
    echo "****** Finished initial Installation *****"
fi


echo "Start NGINX"
/etc/init.d/nginx start
#/etc/init.d/avahi-daemon start
echo "Start Avahi Daemon"
exec avahi-daemon --no-chroot &
echo "Sphinx Index"
rake ts:index
echo "Starting DBServer"
god start docbox -c docbox.god.rb -D
echo "Starting Service: DONE"
sleep infinity
