require 'spec_helper'

describe Platform do
	before(:each) do
		FakeFS.deactivate!
	end

	after(:each) do
		FakeFS.activate!
	end

	context '::CONFIG_PATH' do
		it 'should be readable' do
			path = Platform::CONFIG_PATH
			expect( path ).to be_a(String).and be_frozen
			expect( path ).to be_readable_path
		end
	end

	context '::BIN_PATH' do
		it 'should be readable' do
			path = Platform::BIN_PATH
			expect( path ).to be_a(String).and be_frozen
			expect( path ).to be_readable_path
		end
	end

	context '::FONT_PATH' do
		it 'should be accessible' do
			path = Platform::FONT_PATH
			expect( path ).to be_a(String).and be_frozen
			expect( path ).to be_readable_path.and be_writable_path
		end
	end

	context '::PLATFORM_PATH' do
		it 'should be accessible' do
			path = Platform::PLATFORM_PATH
			expect( path ).to be_a(String).and be_frozen
			expect( path ).to be_readable_path
		end
	end

	context '::SHARED_PATH' do
		it 'should be accessible' do
			path = Platform::SHARED_PATH
			expect( path ).to be_a(String).and be_frozen
			expect( path ).to be_readable_path.and be_writable_path
		end
	end

	context '::QUEUE_PATH' do
		it 'should be accessible' do
			path = Platform::QUEUE_PATH
			expect( path ).to be_a(String).and be_frozen
			expect( path ).to be_readable_path.and be_writable_path
		end
	end

	context '::LOGS_PATH' do
		it 'should be writable' do
			path = Platform::LOGS_PATH
			expect( path ).to be_a(String).and be_frozen
			expect( path ).to be_writable_path
		end
	end

	context '::PRODUCT_NAME' do
		it 'should be valid' do
			str = Platform::PRODUCT_NAME
			expect( str ).to be_a(String).and be_frozen
			expect( str ).to match(/^\w+$/)
		end
	end

	context '::PRODUCT_VERSION' do
		it 'should be valid' do
			str = Platform::PRODUCT_VERSION
			expect( str ).to be_a(String).and be_frozen
			expect( str ).to match(/^\d+\.\d+$/)
		end
	end

	context '::PRODUCT_FULLNAME' do
		it 'should be valid' do
			str = Platform::PRODUCT_FULLNAME
			expect( str ).to be_a(String).and be_frozen
			expect( str ).to include(Platform::PRODUCT_NAME).and include(Platform::PRODUCT_VERSION)
		end
	end

	context '::PLATFORM_TYPE' do
		it 'should be valid' do
			str = Platform::PLATFORM_TYPE
			expect( str ).to be_a(String).and be_frozen
		end
	end
end
