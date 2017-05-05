#!/bin/bash

cd /var/weyland/current
nohup bundle exec ruby ./app/run.rb > /dev/null 2>&1 &
