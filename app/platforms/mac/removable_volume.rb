require 'errors'

class RemovableVolume < Volume
	def mount
		# TODO
	end

	def unmount
		# TODO
	end

	def base_path
		Sys::Filesystem.mount_point(@path)
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
		end

		def get_file_system(path)
			Sys::Filesystem.stat(path).base_type
		end

		def get_total_space(path)
			Sys::Filesystem.stat(path).bytes_total
		end

		def get_available_space(path)
			Sys::Filesystem.stat(path).bytes_free
		end
	end
end
