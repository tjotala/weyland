require 'errors'

class Font
	attr_reader :path, :name

	def eql?(rhs)
		$stderr.puts self.inspect
		$stderr.puts rhs.inspect
		self.to_json == rhs.to_json
	end

	def remove
		File.delete(@path)
	rescue Errno::ENOENT
		no_such_resource(@name)
	rescue Errno::EACCES
		forbidden
	end

	def read
		File.open(@path, 'rb') { |f| f.read }
	rescue Errno::ENOENT
		no_such_resource(@name)
	rescue Errno::EACCES
		forbidden
	end
	
	def write(content)
		File.open(@path, 'wb') { |f| f.write(content) }
	rescue Errno::EACCES
		forbidden
	end

	def to_json(*args)
		{
			name: @name,
			size: File.size(@path),
		}.to_json(args)
	end

	class << self
		def create(path, name, content)
			font = Font.new(path, name)
			font.write(content)
			font
		end

		def get(path, name)
			font = Font.new(path, name)
			font.read
			font
		end
	end

	private

	def initialize(path, name)
		@path = path
		@name = name
	end
end
