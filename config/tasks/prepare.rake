namespace :deploy do

	desc "Execute all preparation steps"
	task :prepare => [ "deploy:prepare:system", "deploy:prepare:system_extras", "deploy:prepare:folders", "deploy:prepare:inkscape", "deploy:prepare:axidraw_ext", "deploy:prepare:axidraw_cli" ] do
		# nothing to do here
	end

	namespace :prepare do

		desc "Fetch Raspbian image"
		task :raspbian do
			sh "curl --silent --location --output /tmp/raspbian.zip https://downloads.raspberrypi.org/raspbian_latest"
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
				sudo "apt-get", "-y install tightvncserver"
			end
		end

		desc "Install application specific system extras"
		task :system_extras do
			on roles(:all) do |host|
				sudo "apt-get", "-y install nginx"
				sudo "rm", "-vf /etc/nginx/sites-enabled/default"
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
				sudo "mkdir", "-vp #{fetch(:deploy_to)}"
				sudo "chown", "#{fetch(:user)} #{fetch(:deploy_to)}"
				execute "mkdir", "-vp #{fetch(:deploy_to)}/shared/{logs,users,queue}"
			end
		end

		desc "Create self-signed certificate for SSL"
		task :cert do
			on roles(:all) do |host|
				execute "openssl", "req -x509 -nodes -days 365 -newkey rsa:2048 -keyout #{fetch(:deploy_to)}/shared/weyland.key -subj \"/C=US/ST=Denial/L=Anytown/O=Weyland-Yutani Corp/CN=Peter Weyland\" -out #{fetch(:deploy_to)}/shared/weyland.crt"
			end
		end

		desc "Install Inkscape 0.92"
		task :inkscape do
			on roles(:all) do |host|
				sudo "apt-get", "-y remove inkscape"
				sudo "echo", "deb http://ftp.debian.org/debian jessie-backports main | sudo tee /etc/apt/sources.list.d/inkscape.list"
				sudo "apt-get", "-y update"
				sudo "apt-get", "-t jessie-backports -y --force-yes install inkscape"
				sudo "apt-get", "-y install python-lxml"
			end
		end

		desc "Install AxiDraw Inkscape extensions"
		task :axidraw_ext do
			on roles(:all) do |host|
				temp_folder = "/tmp"
				version = "v1.2.2"
				filename = "AxiDraw_122_MacLinux.zip"
				ext_folder = "/home/#{fetch(:user)}/.config/inkscape/extensions"
				execute "curl", "--silent --location --output #{temp_folder}/#{filename} https://github.com/evil-mad/axidraw/releases/download/#{version}/#{filename}"
				execute "mkdir", "-vp #{ext_folder}"
				execute "unzip", "-o #{temp_folder}/#{filename} -d #{ext_folder}"
				execute "rm", "-v #{temp_folder}/#{filename}"
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

	namespace :local do
		local_deploy_path = '/var/weyland'

		desc "Install nginx"
		task :install do
			run_locally do
				execute "brew", "install nginx" # this barfs due to gems
			end
		end

		desc "Confgure nginx"
		task :setup do
			run_locally do
				root_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
				sudo "mkdir", "-pv #{local_deploy_path}"
				sudo "chown", "-v `whoami` #{local_deploy_path}"
				execute "ln", "-svfh #{root_path} #{local_deploy_path}/current"
				execute "mkdir", "-pv #{local_deploy_path}/shared/{logs,users,queue}"
				sudo "ln", "-svf #{local_deploy_path}/current/config/nginx/pi.conf /usr/local/etc/nginx/servers/weyland.conf"
				execute "openssl", "req -x509 -nodes -days 365 -newkey rsa:2048 -keyout #{local_deploy_path}/shared/weyland.key -subj \"/C=US/ST=Denial/L=Anytown/O=Weyland-Yutani Corp/CN=Peter Weyland\" -out #{local_deploy_path}/shared/weyland.crt"
			end
		end

		desc "Start nginx"
		task :start do
			run_locally do
				sudo "nginx", "-c #{local_deploy_path}/current/config/nginx/mac.conf"
			end
		end

		desc "Stop nginx"
		task :stop do
			run_locally do
				sudo "nginx", "-s stop"
			end
		end

		desc "Reload nginx"
		task :reload do
			run_locally do
				sudo "nginx", "-s reload"
			end
		end
	end
end
