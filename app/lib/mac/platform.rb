module Platform
	require 'open3'

	SHARED_PATH = File.expand_path(File.join(ROOT_PATH, '..', 'shared')).freeze
	QUEUE_PATH = File.expand_path(File.join(SHARED_PATH, 'queue')).freeze
	LOGS_PATH = File.expand_path(File.join(SHARED_PATH, 'logs')).freeze

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
		# no-op - not going to shutdown the Mac
	end

	def self.which(cmd)
		%x[which cmd]
	end
end
