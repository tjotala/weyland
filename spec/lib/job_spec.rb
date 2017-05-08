require 'spec_helper'
require 'json'
require 'job'

describe Job do
	it "should be able to create a new job" do
		path = 'job1'
		content = 'mock content'
		job = Job::create(path, content)
		expect( job.printed? ).to be_false
	end
end
