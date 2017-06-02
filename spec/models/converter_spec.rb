require 'spec_helper'
require 'converter'

describe Converter do
	before(:each) do
		FakeFS.deactivate!
	end

	after(:each) do
		FakeFS.activate!
	end

	it 'should have valid tool path' do
		expect( Converter::TOOL_PATH ).to be_readable_file
		expect( Converter::TOOL_PATH ).to be_executable_file
	end

	it 'should be able to get version information' do
		expect( Converter.new.version ).to match(/Inkscape \d+\.\d+/)
	end
end
