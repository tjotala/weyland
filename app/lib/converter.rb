require File.join(Platform::PLATFORM_PATH, 'converter.rb')

class Converter
	def version
		Platform::run("#{TOOL_PATH} --version")
	end

	def convert(src, dest)
		cmd = "#{TOOL_PATH} --without-gui --export-plain-svg=#{dest} --export-text-to-path #{src}"
		Platform::run("echo #{cmd}; #{cmd}")
	end
end
