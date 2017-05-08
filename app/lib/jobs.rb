require 'fileutils'
require 'securerandom'
require 'thread'

require 'job'

class Jobs
	attr_reader :volume, :plotter

	def initialize(volume, plotter)
		@volume = volume
		@plotter = plotter
		@stopped = false
		@thread = nil
		@queue = Queue.new
		@thread = Thread.new do
			until @stopped do
				job = @queue.pop
				if job.print(@plotter)
					# succeeded to print
					# just leave it be, it's already marked printed
				else
					# failed to print
					# just leave it be, it's already marked failed
				end
			end
		end
	end

	def list
		Dir[File.join(base_path, '*')].map { |path| Job::get(path) }.sort_by { |job| job.created }
	end

	def get(id)
		Job::get(path_from(id))
	end

	def create(svg, name)
		id = new_id
		job = Job::create(path_from(id), id, svg, name)
		@queue.push(job)
		job
	end

	def print(id)
		job = get(id)
		conflicted_resource("already printing") if job.printing?
		too_many_requests("another job is already printing") if @queue.length > 0
		@queue.push(job)
		job
	end

	def purge(id)
		get(id).purge
	end

	def clear
		list.each { |job| job.purge }
	end

	def stop
		@stopped = true
	end

	private

	def base_path
		p = @volume.path
		FileUtils.mkdir_p(p)
		p
	end

	def path_from(id)
		self.class.validate(id)
		File.join(base_path, id)
	end

	def new_id
		SecureRandom.hex(8) # this could generate collisions, but it's good enough for now
	end

	class << self
		def valid_id?(id)
			id =~ /^\h+$/
		end

		def validate(id)
			invalid_argument('id', 'malformed') unless valid_id?(id)
		end
	end
end
