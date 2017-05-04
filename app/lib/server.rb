require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/json'
require 'json'

require 'errors'
require 'jobs'

class AxiDrawServer < Sinatra::Base
	configure do
		set :root, Platform::ROOT_PATH
		set :public_folder, Platform::PUBLIC_PATH
		enable :static
		enable :logging
		set :static_cache_control, [ :public, :max_age => 60 ]
		set :port, 8080
		set :show_exceptions, false
		set :raise_errors, false

		set :jobs, Jobs.new(LocalVolume.new)
	end

	configure :development do
		set :bind, '0.0.0.0' # allow access from other hosts
		set :static_cache_control, [ :public, :max_age => 5 ]
	end

	before do
		content_type :json
		# we don't want the client to cache these API responses
		cache_control :public, :no_store

		if request.content_type =~ /application\/json/ and request.content_length.to_i > 0
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
		clear_token
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
				platform: Platform::name,
				environment: settings.environment,
				time: Time.now.utc.iso8601,
				zone: Time.now.zone,
				offset: Time.now.utc_offset / 60,
				total_space: LocalVolume.new.total_space,
				available_space: LocalVolume.new.available_space,
			}
		end
	end

	#################################################################
	## General
	#################################################################

	##
	# Get Home Page
	#
	# @method GET
	# @return 200 configuration items
	#
	get '/' do
		cache_control :public, :max_age => 60
		send_file(File.join(settings.public_folder, 'index.html'), :type => :html, :disposition => 'inline')
	end

	##
	# Get Configuration
	#
	# @method GET
	# @return 200 configuration items
	#
	get '/api/config' do
		json config
	end

	##
	# Ping Server
	#
	# @method GET
	# @return 200 ok
	#
	get '/api/ping' do
		content_type :text
		'ok'
	end

	##
	# Quit Server
	#
	# @method POST
	# @return 204 ok
	#
	post '/api/quit' do
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
	post '/api/shutdown' do
		Thread.new do
			Kernel::sleep(2)
			Platform::shutdown
		end
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
	get '/api/jobs/?' do
		json jobs.list
	end

	##
	# Get Print Job Metadata
	#
	# @method GET
	# @param id
	# @return 200 print job
	#
	get '/api/jobs/:id' do
		json jobs.get_metadata(params[:id])
	end

	##
	# Get Print Job Contents
	#
	# @method GET
	# @param id
	# @return 200 print job
	#
	get '/api/jobs/:id/content' do
		send_file(jobs.get_content(params[:id]), :type => 'image/svg+xml', :disposition => 'inline')
	end

	##
	# Create New Print Job
	#
	# @method POST
	# @body svg SVG file
	# @return 201 new print job
	# @return 400 bad print job
	#
	post '/api/jobs/?' do
		json jobs.create(@request_json[:svg])
	end

	##
	# Delete Print Job
	#
	# @method DELETE
	# @param id
	# @body password
	# @return 204 no content
	# @return 404 if no such print job
	#
	delete '/api/jobs/:id' do
		jobs.delete(params[:id])
		status 204
	end

end
