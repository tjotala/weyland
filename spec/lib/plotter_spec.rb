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
	end

	it 'should have valid sample file path' do
		expect( Plotter::SAMPLE_PATH ).to be_readable_file
	end
end
