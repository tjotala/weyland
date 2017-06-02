require 'spec_helper'
require 'volume'

describe Volume do
	context '#new' do
		let(:uuid) { Uuid.new_uuid }

		it 'should require id' do
			expect{ Volume.new() }.to raise_error(ArgumentError)
		end

		it 'should require type' do
			expect{ Volume.new({ id: uuid }) }.to raise_error(ArgumentError)
		end

		it 'should require name' do
			expect{ Volume.new({ id: uuid, type: 'vfat' }) }.to raise_error(ArgumentError)
		end

		it 'should require label' do
			expect{ Volume.new({ id: uuid, type: 'vfat', name: 'mockvolume' }) }.to raise_error(ArgumentError)
		end
	end
end
