require 'json'

namespace :deploy do

	desc "Install fonts"
	task :install_fonts do
		on roles(:all) do |host|
			sudo "find", "#{fetch(:deploy_to)}/current/fonts -iname '*.zip' -print0 | xargs -0 -i sudo unzip -o -j '{}' '*.ttf' -d /usr/local/share/fonts"
			sudo "find", "#{fetch(:deploy_to)}/current/fonts -iname '*.ttf' -print0 | xargs -0 -i sudo cp -f '{}' /usr/local/share/fonts"
		end
	end

	after :finishing, :install_fonts

	desc "Start server"
	task :start do
		on roles(:all) do |host|
			sudo "ln", "-sf #{fetch(:deploy_to)}/current/config/weyland.conf /etc/nginx/sites-enabled/weyland"
			sudo "service", "nginx restart"
			execute "bash", "#{fetch(:deploy_to)}/current/bin/run.sh"
		end
	end

	after :finishing, :start

end

namespace :doctor do

	desc "Test print"
	task :test_print do
		on roles(:all) do |host|
			svg = File.read("bin/axidraw_standalone/AxiDraw_trivial.svg")
			body = {
				svg: svg,
				convert: true,
				name: "Test Print",
			}

			temp_filename = 'print.tmp'
			temp_file = File.new(temp_filename, 'w')
			temp_file.write(body.to_json)
			temp_file.close

			puts %x[curl -s -X POST -H "Content-Type: application/json" -d @#{temp_filename} http://#{host}/v1/jobs]

			File::delete(temp_filename)
		end
	end

end
