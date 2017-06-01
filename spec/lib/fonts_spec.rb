require 'spec_helper'
require 'fonts'
# encoding: utf-8

describe Fonts do
	OK_NAMES = [ 'Arial.ttf', 'Courier.ttf', 'Trajan.ttf', 'ComicSans.ttf' ].freeze
	BAD_NAMES = [ '../../../../../etc/evil/injection/attempt', '^%#$^%#&^.ttf' ].freeze

	let(:fonts) { Fonts.new }
	let(:content) { SecureRandom.random_bytes(256).freeze }

	context '#list' do
		it 'should list installed fonts' do
			expect( fonts.list ).to be_empty
		end
	end

	context '#get' do
		BAD_NAMES.each do |name|
			it "should reject bad font name: #{name}" do
				expect{ fonts.get(name) }.to raise_error(ArgumentError)
			end
		end

		OK_NAMES.each do |name|
			it "should fail on non-existent font: #{name}" do
				expect{ fonts.get(name) }.to raise_error(NoSuchResourceError)
			end
		end

		OK_NAMES.each do |name|
			it "should return existing font: #{name}" do
				fonts.add(name, content)
				expect( fonts.get(name).read ).to eql(content)
			end
		end
	end


	context '#add' do
		BAD_NAMES.each do |name|
			it "should reject bad font name: #{name}" do
				expect{ fonts.add(name, content) }.to raise_error(ArgumentError)
			end
		end

		OK_NAMES.each do |name|
			it "should add a new font: #{name}" do
				fonts.add(name, content)
				expect( fonts.get(name).read ).to eql(content)
			end
		end
	end

	context '#remove' do
		BAD_NAMES.each do |name|
			it "should reject bad font name: #{name}" do
				expect{ fonts.remove(name, content) }.to raise_error(ArgumentError)
			end
		end

		OK_NAMES.each do |name|
			it "should fail to remove non-existent font: #{name}" do
				expect{ fonts.remove(name) }.to raise_error(NoSuchResourceError)
			end
		end

		OK_NAMES.each do |name|
			it "should remove an existing font: #{name}" do
				fonts.add(name, content)
				fonts.remove(name)
				expect{ fonts.get(name).read }.to raise_error(NoSuchResourceError)
			end
		end
	end
end
