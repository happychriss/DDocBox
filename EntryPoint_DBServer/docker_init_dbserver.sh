#!/bin/sh
rake db:create
rake db:schema:load
rake db:seed
rake ts:configure
rake ts:index
rake ts:start
rake assets:precompile

