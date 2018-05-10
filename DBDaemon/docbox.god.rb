CDDAEMON_ROOT="//docbox/DBDaemon"
CDDAEMON_LOG="#{CDDAEMON_ROOT}/log"
SUBNET="172.17.0.0"

 #scanner server, in case scanner is connected locally
 God.watch do |w|
   w.start_grace   = 10.seconds
   w.env           = {'BUNDLE_GEMFILE' => '//docbox/DBDaemon/Gemfile'}
   w.name 	  ='scanner_daemon'
   w.group         ='docbox'
   w.dir           = CDDAEMON_ROOT
   w.start         = "bundle exec ruby #{CDDAEMON_ROOT}/cdclient_daemon.rb --service Scanner --uid 101 --prio 1 --subnet #{SUBNET} --port 8971 --avahiprefix production --unpaper_speed y"
   w.log           = "#{CDDAEMON_LOG}/cdscanner.log"
   w.keepalive
 end
#
# #
# #God.watch do |w|
# #  w.start_grace   = 10.seconds
# #  w.env           = {'BUNDLE_GEMFILE' => '//home/docbox/DBDaemons/Gemfile'}
# #  w.name 	  ='hardware_daemon'
# #  w.group         ='docbox'
# #  w.dir           = CDDAEMON_ROOT
# #  w.start         = "bundle exec ruby #{CDDAEMON_ROOT}/cdclient_daemon.rb --service Hardware --uid 102 --prio 0 --subnet #{SUBNET} --port 8972 --avahiprefix production --gpio_server pi --gpio_port 8780"
# #  w.log           = "#{CDDAEMON_ROOT}/cdhardware.log"
# #  w.keepalive
# #end
#
 God.watch do |w|
   w.start_grace   = 10.seconds
   w.env           = {'BUNDLE_GEMFILE' => '//docbox/DBDaemon/Gemfile'}
   w.name 	  ='converter_daemon'
   w.group         ='docbox'
   w.dir           = CDDAEMON_ROOT
   w.start         = "bundle exec ruby #{CDDAEMON_ROOT}/cdclient_daemon.rb --service Converter --uid 103 --prio 0 --subnet #{SUBNET} --port 8973 --avahiprefix production"
   w.log           = "#{CDDAEMON_LOG}/cdconverter.log"
   w.keepalive
 end
