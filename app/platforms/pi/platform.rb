module Platform
	require 'open3'

	CONFIG_PATH = File.join(File::SEPARATOR, 'etc').freeze
	FONT_PATH = File.expand_path(File.join('~', '.fonts')).freeze
	SHARED_PATH = File.join(File::SEPARATOR, 'var', 'weyland', 'shared').freeze
	QUEUE_PATH = File.join(SHARED_PATH, 'queue').freeze
	LOGS_PATH = File.join(SHARED_PATH, 'logs').freeze

	def self.name
		%x[uname -a].chomp.strip
	end

	def self.run(cmd, ignore_errors = false)
		out, err, status = Open3.capture3(cmd)
		conflicted_resource(caller[0]) if status.to_i != 0 and !ignore_errors
		out + err
	end

	def self.quit
		Process.kill('TERM', Process.pid)
	end

	def self.shutdown
		exec('sudo shutdown -h now')
	end
end
