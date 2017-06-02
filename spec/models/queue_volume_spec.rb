require 'spec_helper'
require 'queue_volume'

describe QueueVolume do
	let(:volume) { QueueVolume.new }

	context '#new' do
		it 'should have the correct ID' do
			expect( volume.id ).to eql('queue')
		end
	end

	it 'should be accessible' do
		expect( volume.path ).to be_readable_path.and be_writable_path
	end

	it 'should have more than 1GB of free space' do
		expect( volume.available_space ).to be > 1 * 1024 * 1024 * 1024
	end
end
