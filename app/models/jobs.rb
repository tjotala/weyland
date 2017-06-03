require 'fileutils'
require 'securerandom'
require 'thread'

require 'job'

class Jobs
	attr_reader :volume, :converter, :plotter

	def initialize(volume, converter, plotter)
		@volume = volume
		@converter = converter
		@plotter = plotter
		@stopped = false
		@conversion_queue = Queue.new
		@conversion_thread = Thread.new do
			until @stopped do
				job = @conversion_queue.pop
				if job.convert(@converter)
					# succeeded to convert
					# just leave it be, it's already marked converted
				else
					# failed to convert
					# just leave it be, it's already marked failed
				end
			end
		end
		@print_queue = Queue.new
		@print_thread = Thread.new do
			until @stopped do
				job = @print_queue.pop
				if job.print(@converter, @plotter)
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
		Dir[File.join(base_path, '*')].map { |path| Job::get(path) rescue nil }.compact.sort_by { |job| job.created }
	end

	def get(id)
		Job::get(path_from(id))
	end

	def create(svg, name, convert)
		id = new_id
		job = Job::create(path_from(id), id, svg, name, convert)
		@conversion_queue.push(job) if convert
		job
	end

	def print(id, convert)
		job = get(id)
		conflicted_resource('already printing') if job.printing?
		too_many_requests('another job is already printing') if @print_queue.length > 0
		job.convert = convert unless convert.nil?
		@print_queue.push(job)
		job
	end

	def mail(id)
		job = get(id)
		conflicted_resource('failed to print') if job.failed?
		conflicted_resource('not yet printed') unless job.printed?
		conflicted_resource('already mailed') if job.mailed?
		job.mail
	end

	def purge(id)
		get(id).purge
	end

	def clear
		list.each { |job| job.purge }
		self
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
			id =~ /^\h{16}$/
		end

		def validate(id)
			invalid_argument('id', 'malformed') unless valid_id?(id)
		end
	end
end
