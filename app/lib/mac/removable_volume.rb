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
			# TODO
		end

		def get_available_space(path)
			# TODO
		end
	end
end
