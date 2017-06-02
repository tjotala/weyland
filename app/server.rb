require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/json'
require 'logger'
require 'haml'
require 'json'

Dir[File.join(Platform::MODEL_PATH, '**', '*.rb')].each { |f| require f }

module Http
	module Headers
		CONTENT_TYPE = 'Content-Type'.freeze
		CONTENT_DISPOSITION = 'Content-Disposition'.freeze
		LOCATION = 'Location'.freeze
		LAST_MODIFIED = 'Last-Modified'.freeze
		POWERED_BY = 'X-Powered-By'.freeze
		QUOTE = 'X-Quote'.freeze
	end
end

module MimeTypes
	HTML = Sinatra::Base.mime_type(:html).freeze
	JSON = Sinatra::Base.mime_type(:json).freeze
	PLAINTEXT = Sinatra::Base.mime_type(:txt).freeze
	SVG = Sinatra::Base.mime_type(:svg).freeze
	TRUETYPE = 'application/font-sfnt'.freeze # not application/octet-stream
end

class Server < Sinatra::Base
	::Logger.class_eval { alias :write :'<<' }
	access_logger = ::Logger.new(::File.join(Platform::LOGS_PATH, 'access.log'))
	error_logger = ::File.new(::File.join(Platform::LOGS_PATH, 'error.log'), 'a+')
	error_logger.sync = true
	$stdout = error_logger
	$stderr = error_logger

	WEYLAND_QUOTES = [
		"My name is Peter Weyland, and if you'll indulge me, I'd like to change the world.",
		"There\'s nothing to learn.",
		"Our first true piece of technology, fire...",
		"Very negative way of looking at things.",
		"Doctors, please. The floor is yours.",
	].freeze

	configure do
		set :root, Platform::ROOT_PATH
		set :views, Platform::VIEW_PATH
		set :port, 8080
		set :public_folder, Platform::PUBLIC_PATH
		set :protection, :except => [ :http_origin ]
		enable :static
		set :static_cache_control, [ :public, :max_age => 60 ]
		set :show_exceptions, false
		set :raise_errors, true
		set :dump_errors, false

		enable :logging
		use Rack::CommonLogger, access_logger

		set :jobs, Jobs.new(QueueVolume.new, Converter.new, Plotter.new)
		set :fonts, Fonts.new
	end

	configure :development do
		set :bind, '0.0.0.0' # allow access from other hosts
		set :static_cache_control, [ :public, :max_age => 5 ]
		set :show_exceptions, false
		set :raise_errors, true
		set :dump_errors, false
	end

	before do
	    env['rack.errors'] =  error_logger

		content_type MimeTypes::JSON
		# we don't want the client to cache these API responses
		cache_control :public, :no_store
		headers Http::Headers::QUOTE => "#{WEYLAND_QUOTES.sample} - Peter Weyland"
		headers Http::Headers::POWERED_BY => Platform::PRODUCT_FULLNAME

		if request.content_type =~ /^#{MimeTypes::JSON}/ and request.content_length.to_i > 0
			logger.debug 'parsing request body as JSON'
			request.body.rewind
			@request_json = JSON.parse(request.body.read, :symbolize_names => true)
		end
	end

	not_found do
		json error: "not found: #{request.url}"
	end

	error ArgumentError do
		bad_request(env['sinatra.error'].message)
	end

	error AuthenticationError do
		halt 401, { error: env['sinatra.error'].message }.to_json
	end

	error AuthorizationError do
		halt 403, { error: env['sinatra.error'].message }.to_json
	end

	error NoSuchResourceError do
 		halt 404, { error: env['sinatra.error'].message }.to_json
	end

	error ConflictedResourceError do
 		halt 409, { error: env['sinatra.error'].message }.to_json
	end

	error InternalError do
		halt 500, { error: env['sinatra.error'].message }.to_json
	end

	error NotImplementedError do
		halt 501, { error: env['sinatra.error'].message }.to_json
	end

	helpers do
		def bad_request(msg)
			halt 400, { error: msg }.to_json
		end

		def config
			{
				company: Platform::COMPANY_NAME,
				product: Platform::PRODUCT_NAME,
				version: Platform::PRODUCT_VERSION,
				platform: Platform::name,
				environment: settings.environment,
				time: Time.now.utc.iso8601(9),
				total_space: settings.jobs.volume.total_space,
				available_space: settings.jobs.volume.available_space,
				converter: settings.jobs.converter.version,
			}
		end

		def job_headers(job)
			headers Http::Headers::LOCATION => uri("/v1/jobs/#{job.id}")
			headers Http::Headers::LAST_MODIFIED => job.updated.httpdate
			job
		end
	end

	#################################################################
	## General
	#################################################################

	##
	# Get Views
	#
	# @method GET
	# @return 200
	#
	[ '/', '/:page_id/?' ].each do |url|
		get url do
			page_id = params[:page_id] || 'index'
			not_found unless page_id =~ /\w+/
			content_type MimeTypes::HTML
			begin
				haml page_id.to_sym
			rescue Errno::ENOENT
				send_file(File.join(Platform::PUBLIC_PATH, page_id, 'index.html'))
			end
		end
	end

	##
	# Get Configuration
	#
	# @method GET
	# @return 200 configuration items
	#
  	get '/v1/config' do
		json config
	end

	##
	# Ping Server
	#
	# @method GET
	# @return 200 ok
	#
	get '/v1/ping' do
		content_type MimeTypes::PLAINTEXT
		'ok'
	end

	##
	# Quit Server
	#
	# @method POST
	# @return 204 ok
	#
	post '/v1/quit' do
		Thread.new do
			Kernel::sleep(2)
			Platform::quit
		end
		status 204
	end

	##
	# Shutdown Appliance
	#
	# @method POST
	# @return 204 ok
	#
	post '/v1/shutdown' do
		Thread.new do
			Kernel::sleep(2)
			Platform::shutdown
		end
		status 204
	end

	#################################################################
	## Fonts
	#################################################################

	##
	# Get Fonts
	#
	# @method GET
	# @return 200 list of font names
	#
	get '/v1/fonts/?' do
		status 200
		json settings.fonts.list
	end

	##
	# Get Font
	#
	# @method GET
	# @param font_name
	# @return 200 font file
	#
	get '/v1/fonts/:font_name' do
		status 200
		name = params[:font_name]
		path = settings.fonts.get(name).path
		download = params[:download] == 'true'
		send_file(path, :type => MimeTypes::TRUETYPE, :disposition => download ? 'attachment' : 'inline', :filename => download ? name : nil)
	end

	##
	# Add Font
	#
	# @method PUT
	# @param font_name name of the font
	# @param body new font file
	# @return 204 no content
	#
	put '/v1/fonts/:font_name?' do
		settings.fonts.add(params[:font_name], request.body.read)
		status 204
	end

	##
	# Remove Font
	#
	# @method DELETE
	# @param name name of font to remove
	# @return 204 no content
	#
	delete '/v1/fonts/:font_name?' do
		settings.fonts.remove(params[:font_name])
		status 204
	end

	#################################################################
	## Printer Control
	#################################################################

	##
	# Get Version
	#
	# @method GET
	# @return 200 version string
	# @return 504 failure to communicate with printer
	#
	get '/v1/printer/version/?' do
		ver = settings.jobs.plotter.version
		logger.info "got printer version: #{ver}"
		status 504 if ver.nil?
		body = { version: ver }
		json body
	end

	##
	# Pen Up
	#
	# @method POST
	# @return 204 no content
	#
	post '/v1/printer/pen/up/?' do
		settings.jobs.plotter.pen(:up)
		status 204
	end

	##
	# Pen Down
	#
	# @method POST
	# @return 204 no content
	#
	post '/v1/printer/pen/down/?' do
		settings.jobs.plotter.pen(:down)
		status 204
	end

	#################################################################
	## Print Jobs
	#################################################################

	##
	# List Print Jobs
	#
	# @method GET
	# @return 200 list of print jobs
	#
	get '/v1/jobs/?' do
		json settings.jobs.list
	end

	##
	# Get Print Job Metadata
	#
	# @method GET
	# @param id job ID
	# @return 200 print job
	#
	get '/v1/jobs/:id' do
		job = settings.jobs.get(params[:id])
		json job_headers(job)
	end

	##
	# Get Print Job Contents
	#
	# @method GET
	# @param id job ID
	# @param download true = download as attachment, false (default) = inline
	# @return 200 print job
	#
	get '/v1/jobs/:id/contents/:which' do
		job = settings.jobs.get(params[:id])
		path, type, name = *case params[:which]
		when 'original'
			[ job.original_content_name, MimeTypes::SVG, "#{job.name}.svg" ]
		when 'converted'
			[ job.converted_content_name, MimeTypes::SVG, "#{job.name}.svg" ]
		when 'conversion_log'
			[ job.conversion_log_name, MimeTypes::PLAINTEXT, "#{job.name}.log" ]
		when 'print_log'
			[ job.print_log_name, MimeTypes::PLAINTEXT, "#{job.name}.log" ]
		else
			not_found
		end
		download = params[:download] == 'true'
		job_headers(job)
		send_file(path, :type => type, :disposition => download ? 'attachment' : 'inline', :filename => download ? name : nil)
	end

	##
	# Create New Print Job
	#
	# @method POST
	# @body svg SVG file
	# @body name name (optional)
	# @body convert convert: true/false (optional)
	# @return 201 new print job
	# @return 400 bad print job
	#
	post '/v1/jobs/?' do
		status 201
		job = settings.jobs.create(@request_json[:svg], @request_json[:name], @request_json[:convert].nil? ? nil : @request_json[:convert])
		json job_headers(job)
	end

	##
	# Print a Job
	#
	# @method POST
	# @param id job ID
	# @param convert convert: true/false (optional, default is false)
	# @return 200 OK
	# @return 404 bad print job ID
	# @return 409 already printing
	#
	post '/v1/jobs/:id/print' do
		status 200
		job = settings.jobs.print(params[:id], params[:convert].nil? ? nil : params[:convert] == 'true')
		json job_headers(job)
	end

	##
	# Mark a Print Job as Mailed
	#
	# @method POST
	# @param id job ID
	# @return 200 OK
	# @return 404 bad print job ID
	# @return 409 failed to print
	# @return 409 not printed
	# @return 409 already mailed
	#
	post '/v1/jobs/:id/mail' do
		status 200
		job = settings.jobs.mail(params[:id])
		json job_headers(job)
	end

	##
	# Delete Print Job
	#
	# @method DELETE
	# @param id job ID
	# @return 200 no content
	# @return 404 if no such print job
	#
	delete '/v1/jobs/:id' do
		status 200
		job = settings.jobs.purge(params[:id])
		json job
	end

	##
	# Delete All Print Jobs
	#
	# @method DELETE
	# @param id
	# @return 204 no content
	#
	delete '/v1/jobs/?' do
		settings.jobs.clear()
		status 204
	end

end
