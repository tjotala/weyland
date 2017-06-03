require 'errors'

class RemovableVolume < Volume
	def mount
		# TODO
	end

	def unmount
		# TODO
	end

	def base_path
		self.class.statfs(@path)[:mounted]
	end

	class << self
		def list
			# TODO
		end

		def get(id)
			# TODO
		end

		def get_interface(path)
			# TODO
			nil
		end

		def get_file_system(path)
			# TODO
			nil
		end

 		def get_total_space(path)
			statfs(path)[:total]
 		end
 
 		def get_available_space(path)
			statfs(path)[:available]
		end

		private

		def statfs(path)
			df = %x[df -k #{path}].lines[1].chomp.split
			{ total: df[3].to_i * 1024, available: df[2].to_i * 1024, mounted: df[8] }
 		end
	end
end
