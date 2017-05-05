namespace :deploy do

	desc "Execute all preparation steps"
	task :prepare => [ "deploy:prepare:system", "deploy:prepare:folders", "deploy:prepare:inkscape", "deploy:prepare:axidraw_ext", "deploy:prepare:axidraw_cli" ] do
		# nothing to do here
	end

	namespace :prepare do

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
				sudo "apt-get", "-y update"
				sudo "apt-get", "-y upgrade"
				sudo "apt-get", "-y install ntpdate"
				sudo "ntpdate", "-u pool.ntp.org"
				sudo "gem", "install bundler --no-document"
			end
		end

		desc "Create root folders"
		task :folders do
			on roles(:all) do |host|
				sudo "mkdir", "-p /var/weyland/queue"
				sudo "chown", "#{fetch(:user)} /var/weyland"
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

		desc "Install AxiDraw CLI"
		task :axidraw_cli do
			on roles(:all) do |host|
				execute "pip", "install lxml"
			end
		end
	end

	desc "Start server"
	task :start do
		on roles(:all) do |host|
			execute "bash", "#{fetch(:deploy_to)}/current/bin/run.sh"
		end
	end

	after :finishing, :start
end
