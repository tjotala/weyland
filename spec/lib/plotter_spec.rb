require 'spec_helper'
require 'plotter'

describe Plotter do
	before(:each) do
		FakeFS.deactivate!
	end

	after(:each) do
		FakeFS.activate!
	end

	it 'should have valid tool path' do
		expect( Plotter::TOOL_PATH ).to be_readable_file
		expect( Plotter::TOOL_PATH ).to be_executable_file
	end
end
