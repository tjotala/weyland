require 'spec_helper'
require 'jobs'
# encoding: utf-8

describe Jobs do
	let(:volume) { QueueVolume.new }
	let(:converter) { double('Converter') }
	let(:plotter) { double('Plotter') }
	let(:jobs) { Jobs.new(volume, converter, plotter) }
	let(:id) { SecureRandom.hex(8) }
	let(:svg) { SecureRandom.random_bytes(256) }
	let(:name) { 'test.svg' }

	context 'with empty job queue' do
		context '#list' do
			it 'should return empty list' do
				expect( jobs.list ).to be_empty
			end
		end

		context '#get' do
			it 'should reject bad job IDs' do
				expect{ jobs.get('bogus&^#&^#_') }.to raise_error(ArgumentError)
				expect{ jobs.get('bogus1-2-3') }.to raise_error(ArgumentError)
				expect{ jobs.get(SecureRandom.hex(4)) }.to raise_error(ArgumentError)
				expect{ jobs.get(SecureRandom.hex(64)) }.to raise_error(ArgumentError)
				expect{ jobs.get(" #{id}") }.to raise_error(ArgumentError)
				expect{ jobs.get("#{id} ") }.to raise_error(ArgumentError)
			end

			it 'should not reject valid job IDs' do
				expect{ jobs.get(id) }.not_to raise_error(ArgumentError)
				expect{ jobs.get('0123456789abcdef') }.not_to raise_error(ArgumentError)
			end

			it 'should fail to retrieve job (there are none)' do
				expect{ jobs.get(id) }.to raise_error(NoSuchResourceError)
			end
		end

		context '#clear' do
			it 'should clear empty list' do
				expect( jobs.clear.list ).to be_empty
			end
		end
	end

	context '#create' do
		it 'should not convert a new job' do
			expect( converter ).not_to receive(:convert)
			job = jobs.create(svg, name, false)
			expect( jobs.list.size ).to be == 1
			expect( jobs.get(job.id) ).to eql(job)
			expect( jobs.get(job.id).pending? ).to be true
		end

		it 'should convert a new job' do
			expect( converter ).to receive(:convert).once.and_return('success')
			job = jobs.create(svg, name, true)
			expect( jobs.list.size ).to be == 1
			expect( jobs.get(job.id) ).to eql(job)
			wait_for{ jobs.get(job.id).converted? }.to be true # done by a thread
		end
	end
end
