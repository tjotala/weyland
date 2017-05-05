class Plotter
	def version
		manual('version-check')
	end

	def reset
		resume('justGoHome')
		motors(:off)
	end

	def motors(state = :on)
		manual(state == :on ? 'enable-motors' : 'disable-motors')
	end

	def pen(dir = :up)
		manual(dir == :up ? 'raise-pen' : 'lower-pen')
	end

	def plot(filename)
		execute('plot', '--reportTime=true', filename)
	end

	private

	def manual(cmd)
		execute('manual', "--manualType=#{cmd}")
	end

	def resume(cmd)
		execute('resume', "--resumeType=#{cmd}")
	end

	def execute(mode, opt, file = 'bogus.svg')
		Platform.run("python axicli.py --mode=#{mode} #{opt} #{filename}")
	end
end
