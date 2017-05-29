require 'errors'

class RemovableVolume < Volume
	def mount
		# TODO
	end

	def unmount
		# TODO
	end

	def base_path
		# TODO
	end

	class << self
		def parse(vol)
			# TODO
		end

		def list
			# TODO
		end

		def get(id)
			# TODO
		end

		def get_interface(path)
			# TODO
		end

		def get_file_system(path)
			# TODO
		end

		def get_total_space(path)
			get_space(path)[:total]
		end

		def get_available_space(path)
			get_space(path)[:available]
		end

		private

		def get_space(path)
			df = %x[df -k #{path}].lines[1].chomp.split
			{ total: df[3].to_i, available: df[2].to_i }
		end
	end
end
