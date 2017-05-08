require 'spec_helper'
require 'json'
require 'plotter'

describe Plotter do
	it "should have valid tool path" do
		expect( File.exist(Plotter.new.TOOL_PATH) ).to be_true
	end
end
