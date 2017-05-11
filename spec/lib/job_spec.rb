require 'spec_helper'
require 'json'
require 'job'

describe Job do
	let(:id) { SecureRandom.hex(8) }
	let(:path) { File.join(Platform::QUEUE_PATH, id) }
	let(:content) { '<svg...mock_attr="foobar"></svg>' }
	let(:name) { 'mock name' }

	describe :create do
		it 'should create a new job with defaults' do
			job = Job::create(path, id, content, name, nil)
			expect( job.id ).to be == id
			expect( job.name ).to be == name
			expect( job.size ).to be == content.length
			expect( job.created ).to be < Time.now
			expect( job.updated ).to be < Time.now
			expect( job.status ).to be == Job::STATUS_PENDING
			expect( job ).to be_pending
			expect( job ).not_to be_printing
			expect( job ).not_to be_printed
			expect( job ).not_to be_failed
			expect( job ).not_to be_convert
			expect( job ).to be_printable
			expect( Job::job_name(path) ).to be_readable_file
			expect( job.content_name ).to be_readable_file
		end

		it 'should accept conversion override' do
			job = Job::create(path, id, content, name, true)
			expect( job.id ).to be == id
			expect( job.name ).to be == name
			expect( job.size ).to be == content.length
			expect( job.created ).to be < Time.now
			expect( job.updated ).to be < Time.now
			expect( job.status ).to be == Job::STATUS_PENDING
			expect( job ).to be_pending
			expect( job ).not_to be_printing
			expect( job ).not_to be_printed
			expect( job ).not_to be_failed
			expect( job ).to be_convert
			expect( job ).to be_printable
			expect( Job::job_name(path) ).to be_readable_file
			expect( job.content_name ).to be_readable_file
		end
	end

	describe :get do
		it 'should read the job' do
			job = Job::create(path, id, content, name, nil)
			expect( Job::get(path) ).to eql(job)
		end
	end

	describe :purge do
		it 'should clean up everything' do
			job = Job::create(path, id, content, name, nil)
			job.purge
			expect{ Job::get(path) }.to raise_error(NoSuchResourceError)
			expect( job.status ).to eq(Job::STATUS_DELETED)
		end

		it 'should not fail even if someone else already cleaned up' do
			job = Job::create(path, id, content, name, nil)
			job.purge # 1st time
			expect{ job.purge }.not_to raise_error(NoSuchResourceError)
		end
	end

	describe :to_json do
		it 'should render proper JSON' do
			job = Job::create(path, id, content, name, nil)
			expect( job.to_json ).to be_a(String)
			json = JSON::parse(job.to_json, symbolize_names: true)
			expect( json[:id] ).to be == id
			expect( json[:name] ).to be == name
			expect( json[:size] ).to be == content.length
			expect( json[:status] ).to be == Job::STATUS_PENDING
			expect( Time.parse(json[:created]) ).to be < Time.now
			expect( Time.parse(json[:updated]) ).to be < Time.now
			expect( json[:convert] ).to be == nil
			expect( json[:printable] ).to be == true
		end
	end

	describe :convert= do
		it 'should update date stamp but not status' do
			job = Job::create(path, id, content, name, nil)
			expect{ job.convert = true }.to change(job, :updated)
			expect( job ).to be_convert
			expect( job.status ).to be == Job::STATUS_PENDING
			expect( job ).to be_printable
		end
	end

	describe :convert do
		it 'should convert the file' do
			job = Job::create(path, id, content, name, false)
			# mock the converter because this test is not for actual conversion
			converter = double('Converter')
			expect( converter ).to receive(:convert).with(job.content_name, job.print_name).and_return('success!')
			expect{ job.convert(converter) }.to change(job, :updated).and change(job, :status)
		end
	end

	describe :print do
		it 'should print without conversion' do
			job = Job::create(path, id, content, name, false)
			# mock the plotter since we don't want to have a hardware dependency
			plotter = double('Plotter')
			expect( plotter ).to receive(:plot).with(job.content_name)
			expect( plotter ).to receive(:home)
			expect( plotter ).to receive(:pen).with(:up)
			expect{ job.print(nil, plotter) }.to change(job, :updated).and change(job, :status)
		end
	end
end
