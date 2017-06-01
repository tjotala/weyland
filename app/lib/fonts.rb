require 'errors'
require 'font'

class Fonts
	BASE_PATH = Platform::FONT_PATH

	def list
		Dir[File.join(BASE_PATH, '*')].map { |path| Font::get(path, File.basename(path)) }.sort_by { |font| font.name }
	end

	def get(name)
		Font::get(path_from(name), name)
	end

	def add(name, content)
		Font::create(path_from(name), name, content)
	end

	def remove(name)
		get(name).remove
	end

	private

	def path_from(name)
		self.class.validate(name)
		File.join(BASE_PATH, name)
	end

	class << self
		def valid_name?(name)
			name =~ /^[\w\-]+\.ttf$/
		end

		def validate(name)
			invalid_argument('name', "malformed: '#{name}'") unless valid_name?(name)
		end
	end
end
