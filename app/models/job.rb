require 'fileutils'
require 'time'

require 'errors'

class Job
	attr_reader :path, :id, :name, :size, :created, :updated, :status

	STATUS_PENDING = 'pending'.freeze
	STATUS_CONVERTING = 'converting'.freeze
	STATUS_CONVERTED = 'converted'.freeze
	STATUS_PRINTING = 'printing'.freeze
	STATUS_PRINTED = 'printed'.freeze
	STATUS_FAILED = 'failed'.freeze
	STATUS_MAILED = 'mailed'.freeze
	STATUS_DELETED = 'deleted'.freeze

	def eql?(rhs)
		self.to_json == rhs.to_json
	end

	def pending?
		@status == STATUS_PENDING
	end

	def convert?
		@convert
	end

	def converting?
		@status == STATUS_CONVERTING
	end

	def converted?
		@status == STATUS_CONVERTED
	end

	def printing?
		@status == STATUS_PRINTING
	end

	def printed?
		@status == STATUS_PRINTED
	end

	def failed?
		@status == STATUS_FAILED
	end

	def mailed?
		@status == STATUS_MAILED
	end

	def deleted?
		@status == STATUS_DELETED
	end

	def printable?
		!(converting? || printing? || deleted?)
	end

	def mailable?
		printed? && !mailed?
	end

	def convert=(state)
		@convert = state
		save
	end

	def convert(converter)
		save(STATUS_CONVERTING)
		conversion_log = converter.convert(original_content_name, converted_content_name)
		File.write(conversion_log_name, conversion_log)
		conflicted_resource('conversion failed') if conversion_log =~ /error/m
		save(STATUS_CONVERTED)
	rescue Exception => e
		save(STATUS_FAILED)
		$stderr.puts "failed to convert, reason: #{e.message}"
		raise e
	end

	def print(converter, plotter)
		if (convert? || converted?)
			convert(converter) unless File.exist?(converted_content_name)
			save(STATUS_PRINTING)
			print_log = plotter.plot(converted_content_name)
		else
			save(STATUS_PRINTING)
			print_log = plotter.plot(original_content_name)
		end
		File.write(print_log_name, print_log) unless print_log.nil?
		save(STATUS_PRINTED)
		plotter.pen(:up)
		plotter.home
		true
	rescue Exception => e
		save(STATUS_FAILED)
		$stderr.puts "failed to print, reason: #{e.message}"
		false
	end

	def mail
		save(STATUS_MAILED)
	end

	def purge
		FileUtils.rm_rf(@path)
		@status = STATUS_DELETED # not persisted though
		self
	rescue Errno::ENOENT
		no_such_resource(@id)
	rescue Errno::EACCES
		forbidden
	end

	def to_json(*args)
		basic = {
			id: @id,
			name: @name,
			size: @size,
			created: @created.utc.iso8601(9),
			updated: @updated.utc.iso8601(9),
			status: @status,
			convert: @convert,
			printable: printable?,
			mailable: mailable?,
		}
		print_log = File.read(print_log_name) rescue nil
		if print_log
			begin
				basic[:print_stats] = {
					elapsed: Time.parse(print_log[/Elapsed time: (\d+:\d+:\d+)/, 1]).strftime('%H:%M:%S'),
					drawn: print_log[/Length of path drawn: (\d+\.\d+)/, 1].to_f,
					moved: print_log[/Total distance moved: (\d+\.\d+)/, 1].to_f,
				}
			rescue
				# do nothing - garbage in the log file (such as when it failed to print)
			end
		end
		basic.select { |k, v| v }.to_json(args)
	end

	def original_content_name
		File.join(@path, 'content.svg')
	end

	def converted_content_name
		File.join(@path, 'print.svg')
	end

	def conversion_log_name
		File.join(@path, 'conversion.log')
	end

	def print_log_name
		File.join(@path, 'print.log')
	end

	def save(new_status = nil)
		@status = new_status || @status
		@updated = Time.now
		File.write(self.class.job_name(@path), to_json)
		self
	end

	private

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

		def create(path, id, content, name, convert = nil)
			FileUtils.mkdir(path)
			job = Job.new(path: path, id: id, name: name, size: content.bytesize, convert: convert).save
			File.write(job.original_content_name, content)
			job
		rescue Errno::EACCES
			forbidden
		end

		def get(path)
			json = JSON::parse(File.read(job_name(path)), symbolize_names: true)
			json[:created] = Time.parse(json[:created])
			json[:updated] = Time.parse(json[:updated])
			json[:path] = path
			Job.new(json)
		rescue Errno::ENOENT
			no_such_resource(File::basename(path))
		rescue Errno::EACCES
			forbidden
		end
	end
end
