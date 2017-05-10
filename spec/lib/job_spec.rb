require 'spec_helper'
require 'json'
require 'job'

describe Job do
	let(:id) { SecureRandom.hex(8) }
	let(:path) { File.join(Platform::QUEUE_PATH, id) }
	let(:content) { '<svg...mock_attr="foobar"></svg>' }
	let(:name) { 'mock name' }

	describe :create do
		it "should create a new job with defaults" do
			job = Job::create(path, id, content, name, nil)
			expect( job.id ).to be(id)
			expect( job.name ).to be(name)
			expect( job.size ).to be(content.length)
			expect( job.created ).to be < Time.now
			expect( job.updated ).to be < Time.now
			expect( job.status ).to be(Job::STATUS_PENDING)
			expect( job.pending? ).to be(true)
			expect( job.printing? ).to be(false)
			expect( job.printed? ).to be(false)
			expect( job.failed? ).to be(false)
			expect( job.convert ).to be(false)
			expect( Job::job_name(path) ).to be_readable_file
			expect( job.content_name ).to be_readable_file
		end

		it "should accept conversion override" do
			job = Job::create(path, id, content, name, true)
			expect( job.id ).to be(id)
			expect( job.name ).to be(name)
			expect( job.size ).to be(content.length)
			expect( job.created ).to be < Time.now
			expect( job.updated ).to be < Time.now
			expect( job.status ).to be(Job::STATUS_PENDING)
			expect( job.pending? ).to be(true)
			expect( job.printing? ).to be(false)
			expect( job.printed? ).to be(false)
			expect( job.failed? ).to be(false)
			expect( job.convert ).to be(true)
			expect( Job::job_name(path) ).to be_readable_file
			expect( job.content_name ).to be_readable_file
		end
	end

	describe :get do
		it "should read the job" do
			job = Job::create(path, id, content, name, nil)
			expect( Job::get(path) ).to eql(job)
		end
	end

	describe :purge do
		it "should clean up everything" do
			job = Job::create(path, id, content, name, nil)
			job.purge
			expect{ Job::get(path) }.to raise_error(NoSuchResourceError)
			expect( job.status ).to eq(Job::STATUS_DELETED)
		end

		it "should not fail even if someone else already cleaned up" do
			job = Job::create(path, id, content, name, nil)
			job.purge # 1st time
			expect{ job.purge }.not_to raise_error(NoSuchResourceError)
		end
	end

	describe :to_json do
		it "should render proper JSON" do
			job = Job::create(path, id, content, name, nil)
			expect( job.to_json ).to be_a(String)
			json = JSON::parse(job.to_json, symbolize_names: true)
			expect( json[:id] ).to be == id
			expect( json[:name] ).to be == name
			expect( Time.parse(json[:created]) ).to be < Time.now
			expect( Time.parse(json[:updated]) ).to be < Time.now
		end
	end

	describe :convert do
		it "should update date stamp" do
			job = Job::create(path, id, content, name, nil)
			expect{ job.convert = true }.to change(job, :updated)
		end
	end

	describe :print do
		it "should print without conversion" do
			job = Job::create(path, id, content, name, false)
			# mock the plotter since we don't want to have a hardware dependency
			plotter = double("Plotter")
			expect( plotter ).to receive(:plot).with(job.content_name)
			expect( plotter ).to receive(:home)
			expect{ job.print(nil, plotter) }.to change(job, :updated).and change(job, :status)
		end
	end
end
