require 'json'

namespace :deploy do

	desc "Install fonts"
	task :install_fonts do
		on roles(:all) do |host|
			src_font_path = "#{fetch(:deploy_to)}/current/fonts"
			tgt_font_path = '~/.fonts'
			execute "mkdir", "-p #{tgt_font_path}"
			execute "find", "#{src_font_path} -iname '*.zip' -print0 | xargs -0 -i unzip -o -j '{}' '*.ttf' -d #{tgt_font_path}"
			execute "find", "#{src_font_path} -iname '*.ttf' -print0 | xargs -0 -i cp -vf '{}' #{tgt_font_path}"
		end
	end

	after :finishing, :install_fonts

	desc "Start server"
	task :start do
		on roles(:all) do |host|
			sudo "rm", "-rf /etc/nginx/sites-enabled/weyland" # remove old name
			sudo "ln", "-svf #{fetch(:deploy_to)}/current/config/nginx/pi.conf /etc/nginx/sites-enabled/weyland.conf"
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
