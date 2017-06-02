#!/usr/bin/ruby
require 'bundler/setup'

require File.join(File.dirname(File.expand_path(__FILE__)), 'platform')
require 'server'

Server.run!
