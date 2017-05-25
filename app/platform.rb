module Platform
	require 'yaml'

	ROOT_PATH = File.expand_path(File.dirname(__FILE__)).freeze
	LIB_PATH = File.expand_path(File.join(ROOT_PATH, 'lib')).freeze
	BIN_PATH = File.expand_path(File.join(ROOT_PATH, '..', 'bin')).freeze
	CONFIG_PATH = File.expand_path(File.join(ROOT_PATH, '..', 'config')).freeze
	PUBLIC_PATH = File.expand_path(File.join(ROOT_PATH, '..', 'public')).freeze

	PRODUCT_CONFIG = (YAML.load(File.read(File.join(CONFIG_PATH, 'product.yaml'))) rescue { }).freeze

	COMPANY_NAME = (PRODUCT_CONFIG['company_name'] || '').freeze
	PRODUCT_NAME = (PRODUCT_CONFIG['product_name'] || 'Weyland').freeze
	PRODUCT_VERSION = (PRODUCT_CONFIG['product_version'] || '1.0').freeze
	PRODUCT_LOGO = (PRODUCT_CONFIG['product_logo'] || nil).freeze
	PRODUCT_FULLNAME = "#{PRODUCT_NAME}/#{PRODUCT_VERSION}".freeze

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

	PLATFORM_PATH = File.join(LIB_PATH, PLATFORM_TYPE).freeze
	$LOAD_PATH.unshift(Platform::LIB_PATH, Platform::PLATFORM_PATH)
end

require File.join(Platform::PLATFORM_PATH, 'platform.rb')
