module Platform
	ROOT_PATH = File.dirname(File.expand_path(__FILE__)).freeze
	BIN_PATH = File.join(ROOT_PATH, '..', 'bin').freeze
	PUBLIC_PATH = File.join(ROOT_PATH, '..', 'public').freeze
	MODEL_PATH = File.join(ROOT_PATH, 'models').freeze
	VIEW_PATH = File.join(ROOT_PATH, 'views').freeze

	PLATFORM_TYPE_PI = 'pi'.freeze
	PLATFORM_TYPE_MAC = 'mac'.freeze
	PLATFORM_TYPE_WIN = 'win'.freeze

	case RUBY_PLATFORM
	when /arm-linux/
		PLATFORM_TYPE = PLATFORM_TYPE_PI
	when /darwin/
		PLATFORM_TYPE = PLATFORM_TYPE_MAC
	when /mswin/
		PLATFORM_TYPE = PLATFORM_TYPE_WIN
	else
		raise "unsupported platform: #{RUBY_PLATFORM}"
	end

	PLATFORM_PATH = File.join(ROOT_PATH, 'platforms', PLATFORM_TYPE).freeze
	$LOAD_PATH.unshift(Platform::MODEL_PATH, Platform::PLATFORM_PATH, Platform::ROOT_PATH)
end

require File.join(Platform::PLATFORM_PATH, 'platform.rb')

module Platform
	LOGS_PATH = File.join(SHARED_PATH, 'logs').freeze
	USERS_PATH = File.join(SHARED_PATH, 'users').freeze
	QUEUE_PATH = File.join(SHARED_PATH, 'queue').freeze

	require 'yaml'

	PRODUCT_CONFIG = (YAML.load(File.read(File.join(CONFIG_PATH, 'weyland.conf'))) rescue { }).freeze

	COMPANY_NAME = (PRODUCT_CONFIG['company_name'] || '').freeze
	PRODUCT_NAME = (PRODUCT_CONFIG['product_name'] || 'Weyland').freeze
	PRODUCT_VERSION = (PRODUCT_CONFIG['product_version'] || '1.0').to_s.freeze
	PRODUCT_LOGO = (PRODUCT_CONFIG['product_logo'] || nil).freeze
	PRODUCT_FULLNAME = "#{PRODUCT_NAME}/#{PRODUCT_VERSION}".freeze
end

puts "CONFIG_PATH = #{Platform::CONFIG_PATH}"
puts "FONT_PATH = #{Platform::FONT_PATH}"
puts "ROOT_PATH = #{Platform::ROOT_PATH}"
puts "SHARED_PATH = #{Platform::SHARED_PATH}"
puts "LOGS_PATH = #{Platform::LOGS_PATH}"
puts "USERS_PATH = #{Platform::USERS_PATH}"
puts "QUEUE_PATH = #{Platform::QUEUE_PATH}"
