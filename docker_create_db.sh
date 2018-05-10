#!/bin/sh
rake db:create
rake db:schema:load
rake db:seed
