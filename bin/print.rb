#!/usr/bin/ruby
require 'json'

ip = ARGV.shift
svg = File.read(ARGV.shift)
body = {
	:svg => svg
}

temp_filename = 'print.tmp'
temp_file = File.new(temp_filename, 'w')
temp_file.write(body.to_json)
temp_file.close

puts %x[curl -v -X POST -H "Content-Type: application/json" -H "Origin: http://#{ip}" -d @#{temp_filename} http://#{ip}/v1/jobs]

File::delete(temp_filename)
