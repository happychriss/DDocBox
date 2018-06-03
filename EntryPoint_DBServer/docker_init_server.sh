#!/bin/sh
cd DBServer
rake db:create
rake db:schema:load
rake db:seed
rake ts:configure
rake ts:index
rake assets:precompile