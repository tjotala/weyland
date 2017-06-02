require 'spec_helper'
require 'json'
require 'job'

describe Job do
	let(:id) { SecureRandom.hex(8) }
	let(:path) { File.join(Platform::QUEUE_PATH, id) }
	let(:content) { '<svg...mock_attr="foobar"></svg>' }
	let(:name) { 'mock name' }

	describe '#create' do
		it 'should create a new job with defaults' do
			job = Job::create(path, id, content, name)
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
			expect( job ).not_to be_mailable
			expect( Job::job_name(path) ).to be_readable_file
			expect( job.original_content_name ).to be_readable_file
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
			expect( job ).not_to be_mailable
			expect( Job::job_name(path) ).to be_readable_file
			expect( job.original_content_name ).to be_readable_file
		end
	end

	describe '#get' do
		it 'should read the job' do
			job = Job::create(path, id, content, name)
			expect( Job::get(path) ).to eql(job)
		end
	end

	describe '#purge' do
		it 'should clean up everything' do
			job = Job::create(path, id, content, name)
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

	describe '#to_json' do
		it 'should render proper JSON' do
			job = Job::create(path, id, content, name)
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

	describe '#convert=' do
		it 'should update date stamp but not status' do
			job = Job::create(path, id, content, name)
			expect{ job.convert = true }.to change(job, :updated)
			expect( job ).to be_convert
			expect( job.status ).to be == Job::STATUS_PENDING
			expect( job ).to be_printable
		end
	end

	describe '#convert' do
		it 'should convert the file' do
			job = Job::create(path, id, content, name)
			old_job = job.clone

			converter = double('Converter')
			expect( converter ).to receive(:convert).once.with(job.original_content_name, job.converted_content_name).and_return('success')

			expect{ job.convert(converter) }.to change(job, :updated).and change(job, :status)
			expect( job.status ).to be == Job::STATUS_CONVERTED
			expect( job.updated ).to be > old_job.updated
		end

		it 'should handle catastrophic conversion failure' do
			job = Job::create(path, id, content, name)
			old_job = job.clone

			converter = double('Converter')
			expect( converter ).to receive(:convert).once.with(job.original_content_name, job.converted_content_name).and_raise(ConflictedResourceError)

			expect{ job.convert(converter) }.to raise_error(ConflictedResourceError)
			expect( job.status ).to be == Job::STATUS_FAILED
			expect( job.updated ).to be > old_job.updated
		end

		it 'should handle simple conversion failure' do
			job = Job::create(path, id, content, name)
			old_job = job.clone

			converter = double('Converter')
			expect( converter ).to receive(:convert).once.with(job.original_content_name, job.converted_content_name).and_return('error')

			expect{ job.convert(converter) }.to raise_error(ConflictedResourceError)
			expect( job.status ).to be == Job::STATUS_FAILED
			expect( job.updated ).to be > old_job.updated
		end
	end

	describe '#print' do
		it 'should print without conversion' do
			job = Job::create(path, id, content, name)
			old_job = job.clone

			plotter = double('Plotter')
			expect( plotter ).to receive(:plot).once.with(job.original_content_name)
			expect( plotter ).to receive(:home).once
			expect( plotter ).to receive(:pen).once.with(:up)

			expect{ job.print(nil, plotter) }.to change(job, :updated).and change(job, :status)
			expect( job.status ).to be == Job::STATUS_PRINTED
			expect( job.updated ).to be > old_job.updated
		end
	end

	describe '#mail' do
		it 'should mark job as mailed' do
			job = Job::create(path, id, content, name)
			old_job = job.clone
			expect{ job.mail }.to change(job, :updated).and change(job, :status)
			expect( job.status ).to be == Job::STATUS_MAILED
			expect( job.updated ).to be > old_job.updated
		end
	end
end
