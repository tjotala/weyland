#!/bin/bash

pid_file=/var/weyland/shared/weyland.pid
if [ -f $pid_file ]; then
  echo killing old server $(cat $pid_file)
  kill $(cat $pid_file)
fi
nohup bundle exec ruby ./app/run.rb > /dev/null 2>&1 &
echo $! > $pid_file
echo launched new server as $(cat $pid_file)
