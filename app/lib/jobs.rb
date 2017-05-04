require 'fileutils'
require 'securerandom'

require 'job'

class Jobs
	def initialize(volume)
		@volume = volume
	end

	def list
		Dir[File.join(base_path, '*')].reject { |path| self.class.exclude?(path) }.map { |path| Job.new(path) }.sort_by { |job| job.created }
	end

	def get_metadata(id)
		Job.new(path_from(id))
	end

	def get_content(id)
		path_from(id)
	end

	def create(svg)
		job = Job.new(path_from(new_id))
		job.create(svg)
	end

	def delete(id)
		Job.new(path_from(id)).remove
	end

	private

	def base_path
		p = @volume.path
		FileUtils.mkdir_p(p)
		p
	end

	def path_from(id)
		validate(id)
		File.join(base_path, id)
	end

	def new_id
		SecureRandom.hex # this could generate collisions, but it's good enough for now
	end

	class << self
		def exclude?(path)
			!valid_id?(File.basename(path))
		end

		def valid_id?(id)
			id =~ /^\h+$/
		end

		def validate(id)
			invalid_argument('id', 'malformed') unless valid_id?(id)
		end
	end
end
