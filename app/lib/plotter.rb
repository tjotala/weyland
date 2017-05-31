class Plotter
	BASE_PATH = File.expand_path(File.join(Platform::BIN_PATH, 'axidraw_standalone')).freeze
	TOOL_PATH = File.expand_path(File.join(BASE_PATH, 'axicli.py')).freeze
	SAMPLE_PATH = File.expand_path(File.join(BASE_PATH, 'AxiDraw_trivial.svg')).freeze

	def version
		ver = manual('version-check')
		return nil if ver.nil?
		return '<not connected>' if ver =~ /Failed to connect to AxiDraw/
		(ver[/(Firmware.+)/, 1] || '<no version>').chomp.strip
	end

	def home
		resume('justGoHome')
	end

	def motors(state = :on)
		manual(state == :on ? 'enable-motors' : 'disable-motors')
	end

	def pen(dir = :up)
		manual(dir == :up ? 'raise-pen' : 'lower-pen')
	end

	def plot(filename)
		execute('plot', '--autoRotate=false --reportTime=true', filename)
	end

	private

	def manual(cmd)
		execute('manual', "--manualType=#{cmd}")
	end

	def resume(cmd)
		execute('resume', "--resumeType=#{cmd}")
	end

	def execute(mode, opt, filename = SAMPLE_PATH)
		Platform::run("cd #{File.dirname(TOOL_PATH)}; python #{TOOL_PATH} --mode=#{mode} #{opt} #{filename} 2>&1", true)
	end
end
