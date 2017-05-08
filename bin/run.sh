#!/bin/bash

cd /var/weyland/current
killall --quiet ruby
nohup bundle exec ruby ./app/run.rb > /dev/null 2>&1 &
