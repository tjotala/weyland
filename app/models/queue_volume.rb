require 'promise'

require 'volume'

class QueueVolume < Volume
	ID = 'queue'.freeze

	def initialize
		super({
			id: ID,
			interface: promise { RemovableVolume::get_interface(@path) },
			name: Platform::PRODUCT_NAME,
			fstype: promise { RemovableVolume::get_file_system(@path) },
			path: Platform::QUEUE_PATH,
			total_space: promise { RemovableVolume::get_total_space(@path) },
			available_space: promise { RemovableVolume::get_available_space(@path) },
		})
	end
end
