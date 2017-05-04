require 'fileutils'

require 'errors'

class Job
	attr_reader :path

	def initialize(path)
		@path = path
	end

	def create(content)
		File.open(@path, 'w') { |f| f.write(content) }
		self
	rescue Errno::EACCES => e
		forbidden
	end

	def remove
		File.unlink(@path)
		self
	rescue Errno::ENOENT => e
		not_found
	rescue Errno::EACCES => e
		forbidden
	end

	def lock
		FileUtils.chmod('u=r,go=rr', @path)
		self
	rescue Errno::ENOENT => e
		not_found
	rescue Errno::EACCES => e
		forbidden
	end

	def unlock
		FileUtils.chmod('u=rw,go=rr', @path)
		self
	rescue Errno::ENOENT => e
		not_found
	rescue Errno::EACCES => e
		forbidden
	end

	def render
		temp_file = "#{@path}.tmp"
		Platform.run("inkscape --without-gui --export-plain-svg=#{temp_file} --export-text-to-path #{@path}")
		Platform.run("python axicli.py #{temp_file}")
	end

	def created
		File.mtime(@path) # yes, mtime
	end

	def to_json(*args)
		stat = File.stat(@path)
		{
			id: File.basename(@path),
			size: stat.size,
			created: stat.ctime.iso8601,
			modified: stat.mtime.iso8601,
			locked: !stat.writable?,
		}.select { |k, v| v }.to_json(args)
	end
end
