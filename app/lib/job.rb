require 'fileutils'
require 'time'

require 'errors'

class Job
	attr_reader :path, :id, :name, :size, :created, :updated, :status, :convert

	STATUS_PENDING = 'pending'
	STATUS_CONVERTING = 'converting'
	STATUS_PRINTING = 'printing'
	STATUS_PRINTED = 'printed'
	STATUS_FAILED = 'failed'

	def ==(rhs)
		@id == rhs.id && @name == rhs.name && @size == rhs.size && @created == rhs.created && @updated == rhs.updated && @status == rhs.status
	end

	def pending?
		@status == STATUS_PENDING
	end

	def printing?
		@status == STATUS_CONVERTING || @status == STATUS_PRINTING
	end

	def printed?
		@status == STATUS_PRINTED
	end

	def failed?
		@status == STATUS_FAILED
	end

	def convert=(state)
		@convert = state
		save
	end

	def print(plotter)
		conversion_log = print_log = nil
		if @convert
			save(STATUS_CONVERTING)
			conversion_log = Platform::run("inkscape --without-gui --export-plain-svg=#{print_name} --export-text-to-path #{content_name}")
			conflicted_resource("conversion failed") if conversion_log =~ /error/m
			save(STATUS_PRINTING)
			print_log = plotter.plot(print_name)
		else
			save(STATUS_PRINTING)
			print_log = plotter.plot(content_name)
		end
		save(STATUS_PRINTED)
		plotter.home
		true
	rescue RuntimeError => e
		save(STATUS_FAILED)
		$stderr.puts "failed to print, reason: #{e.message}"
		false
	rescue
		save(STATUS_FAILED)
		$stderr.puts "failed to print, reason: #{e.message}"
		false
	ensure
		File.write(conversion_log_name, conversion_log) unless conversion_log.nil?
		File.write(print_log_name, print_log) unless print_log.nil?
		#File::delete(print_name) rescue nil
	end

	def purge
		FileUtils.rm_rf(@path)
		self
	rescue Errno::ENOENT => e
		not_found
	rescue Errno::EACCES => e
		forbidden
	end

	def to_json(*args)
		{
			id: @id,
			name: @name,
			size: @size,
			created: @created.utc.iso8601,
			updated: @updated.utc.iso8601,
			status: @status,
			convert: @convert,
		}.select { |k, v| v }.to_json(args)
	end

	def content_name
		File.join(@path, 'content.svg')
	end

	def save(new_status = nil)
		@status = new_status || @status
		@updated = Time.now
		File.write(self.class.job_name(@path), to_json)
		self
	end

	private

	def conversion_log_name
		File.join(@path, 'conversion.log')
	end

	def print_log_name
		File.join(@path, 'print.log')
	end

	def print_name
		File.join(@path, 'print.svg')
	end

	def initialize(obj = { })
		@path = obj[:path]
		@id = obj[:id]
		@name = obj[:name]
		@size = obj[:size]
		@created = obj[:created] || Time.now
		@updated = obj[:updated] || @created
		@status = obj[:status] || STATUS_PENDING
		@convert = obj[:convert].nil? ? false : obj[:convert]
	end

	class << self
		def job_name(path)
			File.join(path, 'job.json')
		end

		def create(path, id, content, name, convert)
			FileUtils.mkdir(path)
			job = Job.new(path: path, id: id, name: name, size: content.bytesize, convert: convert).save
			File.write(job.content_name, content)
			job
		rescue Errno::EACCES => e
			forbidden
		end

		def get(path)
			json = JSON::parse(File.read(job_name(path)), symbolize_names: true)
			json[:created] = Time.parse(json[:created])
			json[:updated] = Time.parse(json[:updated])
			json[:path] = path
			Job.new(json)
		rescue Errno::ENOENT => e
			not_found
		rescue Errno::EACCES => e
			forbidden
		end
	end
end
