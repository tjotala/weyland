namespace :deploy do

	desc "Execute all preparation steps"
	task :prepare => [ "deploy:prepare:system", "deploy:prepare:system_extras", "deploy:prepare:folders", "deploy:prepare:inkscape", "deploy:prepare:axidraw_ext", "deploy:prepare:axidraw_cli" ] do
		# nothing to do here
	end

	namespace :prepare do

		desc "Fetch Raspbian image"
		task :raspbian do
			sh "curl --location --output /tmp/raspbian.zip https://downloads.raspberrypi.org/raspbian_latest"
		end

		desc "Create MicroSD card"
		task :microsd do
			sh "diskutil list"
			set :card, ask("Enter MicroSD device name (/dev/diskN):", "/dev/disk2")
			sh "diskutil unmountDisk #{fetch(:card)}"
			sh "unzip -p /tmp/raspbian.zip | sudo dd bs=1m of=#{fetch(:card).gsub(/disk/, 'rdisk')}"
		end

		desc "Configure SSH"
		task :ssh do
			roles(:all).each do |host|
				sh "ssh-copy-id #{fetch(:user)}@#{host}" do |ok, res|
					# only raise if not redundant copy of key
					raise RuntimeError if !ok and res.exitstatus != 127
				end
			end
		end

		desc "Upgrade base system"
		task :system do
			on roles(:all) do |host|
				sudo "apt-get", "-y remove pulseaudio"
				sudo "apt-get", "-y autoremove"
				sudo "apt-get", "-y update"
				sudo "apt-get", "-y upgrade"
				sudo "apt-get", "-y install ntpdate"
				sudo "ntpdate", "-u pool.ntp.org"
			end
		end

		desc "Install application specific system extras"
		task :system_extras do
			on roles(:all) do |host|
				sudo "apt-get", "-y install nginx"
				sudo "rm", "-f /etc/nginx/sites-enabled/default"
				sudo "gem", "install bundler --no-document"
				execute "echo", ". #{fetch(:deploy_to)}/current/bin/run.sh >> /home/#{fetch(:user)}/.profile"
			end
		end

		desc "Generate SSH deploy key"
		task :generate_deploy_keys do
			on roles(:all) do |host|
				execute "ssh-keygen", "-v -t rsa -b 2048 -N '' -f /home/#{fetch(:user)}/.ssh/id_rsa"
				system "scp #{fetch(:user)}@#{host}:~/.ssh/id_rsa.pub config/#{host}.pub"
			end
		end

		desc "Create root folders"
		task :folders do
			on roles(:all) do |host|
				sudo "mkdir", "-p #{fetch(:deploy_to)}"
				sudo "chown", "#{fetch(:user)} #{fetch(:deploy_to)}"
				execute "mkdir", "-p #{fetch(:deploy_to)}/shared/{logs,queue}"
			end
		end

		desc "Install Inkscape"
		task :inkscape do
			on roles(:all) do |host|
				sudo "apt-get", "-y install inkscape"
				sudo "apt-get", "-y install python-lxml"
			end
		end

		desc "Install AxiDraw Inkscape extensions"
		task :axidraw_ext do
			on roles(:all) do |host|
				temp_folder = "/tmp"
				ext_folder = "/home/#{fetch(:user)}/.config/inkscape/extensions"
				execute "wget", "-P #{temp_folder} https://github.com/evil-mad/axidraw/releases/download/v1.2.2/AxiDraw_122_MacLinux.zip"
				execute "mkdir", "-p #{ext_folder}"
				execute "unzip", "#{temp_folder}/AxiDraw_122_MacLinux.zip -d #{ext_folder}"
				execute "rm", "#{temp_folder}/AxiDraw_122_MacLinux.zip"
			end
		end

		desc "Install AxiDraw CLI dependencies"
		task :axidraw_cli do
			on roles(:all) do |host|
				execute "pip", "install lxml"
				sudo "pip", "install --upgrade pyserial"
			end
		end
	end

end
