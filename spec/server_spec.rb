require 'spec_helper'
require 'server'

describe Server do
	context "web content" do
		before(:each) do
			FakeFS.deactivate!
		end

		after(:each) do
			FakeFS.activate!
		end

		it 'should return homepage' do
			get '/'
			expect( last_response ).to be_ok
			expect( last_response ).to be_html
		end

		it 'should return homepage' do
			get '/index'
			expect( last_response ).to be_ok
			expect( last_response ).to be_html
		end
	end

	context "general APIs" do
		it 'should respond to ping' do
			get '/v1/ping'
			expect( last_response ).to be_ok
			expect( last_response ).to be_plain_text
			expect( last_response.body ).to eq('ok')
		end

		it 'should respond to configuration request' do
			get '/v1/config'
			expect( last_response ).to be_ok
			expect( last_response ).to be_json
		end

		it 'should quit' do
			expect( Kernel ).to receive(:sleep) # and eat it
			expect( Platform ).to receive(:quit) # and eat it
			expect( Thread ).to receive(:new).and_yield # don't spawn the background thread
			post '/v1/quit'
			expect( last_response ).to be_empty
		end

		it 'should shutdown' do
			allow( Kernel ).to receive(:sleep) # and eat it
			expect( Platform ).to receive(:shutdown) # and eat it
			expect( Thread ).to receive(:new).and_yield # don't spawn the background thread
			post '/v1/shutdown'
			expect( last_response ).to be_empty
		end

		it 'should return not found JSON to garbage URL' do
			get "/#{Uuid.new_uuid}"
			expect( last_response ).to be_not_found
			expect( last_response ).to be_json
		end
	end

	context 'fonts APIs' do
		let(:fonts) { [
			{ name: 'foo.ttf', content: SecureRandom.random_bytes(256) },
			{ name: 'bar.ttf', content: SecureRandom.random_bytes(256) },
		] }
		let(:font_list) { fonts.map { |font| { 'name' => font[:name] } } }

		context "with bad input" do
			BAD_NAMES = [ '...evil..', '.,;:=', 'bogus.otf' ]

			BAD_NAMES.each do |name|
				it "should fail to get font with malformed name: #{name}" do
					get "/v1/fonts/#{name}"
					expect( last_response ).to be_bad_request
				end

				it "should fail to install new font with malformed name: #{name}" do
					header Http::Headers::CONTENT_TYPE, MimeTypes::TRUETYPE
					put "/v1/fonts/#{name}", SecureRandom.random_bytes(256)
					expect( last_response ).to be_bad_request
				end

				it "should fail to delete font with malformed name: #{name}" do
					delete "/v1/fonts/#{name}"
					expect( last_response ).to be_bad_request
				end
			end
		end

		context "without installed fonts" do
			it 'should return an empty list of installed fonts' do
				get "/v1/fonts"
				expect( last_response ).to be_json
				expect( JSON::parse(last_response.body) ).to be_empty
			end

			it 'should fail to get non-existent font' do
				get "/v1/fonts/#{fonts[0][:name]}"
				expect( last_response ).to be_not_found
			end

			it 'should fail to remove non-existent font' do
				delete "/v1/fonts/#{fonts[0][:name]}"
				expect( last_response ).to be_not_found
			end

			it 'should add a new font' do
				fonts.each do |font|
					header Http::Headers::CONTENT_TYPE, MimeTypes::TRUETYPE
					put "/v1/fonts/#{font[:name]}", font[:content]
					expect( last_response ).to be_empty
				end
				get "/v1/fonts"
				expect( last_response ).to be_json
				json = JSON::parse(last_response.body)
				expect( json ).to match_array(font_list)
			end
		end

		context "with installed fonts" do
			before(:each) do
				fonts.each do |font|
					header Http::Headers::CONTENT_TYPE, MimeTypes::TRUETYPE
					put "/v1/fonts/#{font[:name]}", font[:content]
					expect( last_response ).to be_empty
				end
			end

			it 'should return a list of installed fonts' do
				get "/v1/fonts"
				expect( last_response ).to be_json
				json = JSON::parse(last_response.body)
				expect( json ).to match_array(font_list)
			end

			it 'should get an existing font as inline' do
				fonts.each do |font|
					get "/v1/fonts/#{font[:name]}", :download => false
					expect( last_response ).to be_ok
					expect( last_response.body ).to eql(font[:content])
					expect( last_response.headers[Http::Headers::CONTENT_TYPE] ).to eql(MimeTypes::TRUETYPE)
					expect( last_response.headers[Http::Headers::CONTENT_DISPOSITION] ).to eql('inline')
				end
			end

			it 'should get an existing font as attachment' do
				fonts.each do |font|
					get "/v1/fonts/#{font[:name]}", :download => true
					expect( last_response ).to be_ok
					expect( last_response.body ).to eql(font[:content])
					expect( last_response.headers[Http::Headers::CONTENT_TYPE] ).to eql(MimeTypes::TRUETYPE)
					expect( last_response.headers[Http::Headers::CONTENT_DISPOSITION] ).to eql(%Q{attachment; filename="#{font[:name]}"})
				end
			end

			it 'should replace an existing font' do
				new_content = SecureRandom.random_bytes(128)
				put "/v1/fonts/#{fonts[0][:name]}", new_content
				expect( last_response ).to be_empty
				get "/v1/fonts/#{fonts[0][:name]}"
				expect( last_response.body ).to eql(new_content)
			end

			it 'should remove an existing font' do
				delete "/v1/fonts/#{fonts[0][:name]}"
				expect( last_response ).to be_empty
				expect( last_response.body ).to be_empty
			end

			it 'should fail to remove non-existent font' do
				delete "/v1/fonts/bogus.ttf"
				expect( last_response ).to be_not_found
			end
		end
	end
end
