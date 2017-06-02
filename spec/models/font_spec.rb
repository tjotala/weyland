require 'spec_helper'
require 'font'
# encoding: utf-8

describe Font do
	let(:name) { 'Arial.ttf' }
	let(:path) { File.join(Platform::FONT_PATH, name) }
	let(:content) { SecureRandom.random_bytes(256).freeze }

	context '::get' do
		it "should fail on non-existent font" do
			expect{ Font::get(path, name) }.to raise_error(NoSuchResourceError)
		end

		it "should return existing font" do
			font = Font::create(path, name, content)
			expect( Font::get(path, name) ).to eql(font)
		end
	end

	context '::create' do
		it "should add a new font" do
			font = Font::create(path, name, content)
			expect( Font::get(path, name) ).to eql(font)
			expect( Font::get(path, name).read ).to eql(content)
		end
	end

	context '#to_json' do
		it "should render proper JSON" do
			font = Font::create(path, name, content)
			expect( font.to_json ).to be_a(String)
			json = JSON::parse(font.to_json, symbolize_names: true)
			expect( json[:name] ).to be == name
		end
	end

	context '#remove' do
		it "should remove an existing font" do
			font = Font::create(path, name, content)
			font.remove
			expect{ Font::get(path, name) }.to raise_error(NoSuchResourceError)
		end
	end

	context '#read' do
		it "should read an existing font" do
			font = Font::create(path, name, content)
			expect( font.read ).to eql(content)
		end
	end

	context '#write' do
		it "should write new font content" do
			font = Font::create(path, name, content)
			font.write(content.reverse)
			expect( font.read ).to eql(content.reverse)
		end
	end
end
