at_exit { cleanup } 

require 'sinatra'
require 'json'


@@html_code = File.read("webcam.html")

@@config = {}
@@tokens = {}



def reload_config
	@@config = JSON.parse(File.read("config.json"))
	@@tokens = @@config["tokens"]
end

def reload_config_token_is_ok?(token)
	@@config["reload_token"] == token
end

def token_valid?(token, opts)
	unless @@tokens[token].nil?
		tk = @@tokens[token]
		p tk
		ret_val = true
		ret_val = false if tk["ip_lock"] and tk[:ip] and tk[:ip] != opts[:ip]
		ret_val = false if tk[:valid_until] and tk[:valid_until] < Time.now.to_i
		ret_val = false if tk["max_loads"] and ( tk[:loads] || 1 ) > tk["max_loads"].to_i

		if ret_val then
			tk[:ip] = opts[:ip]
			if tk["valid_for"] and !tk[:valid_until]
				tk[:valid_until] = Time.now.to_i + tk["valid_for"].to_i
			end
			tk[:loads] = (tk[:loads] || 1) + 1
		end

		puts 
		ret_val
	else
		false
	end
end

def start_if_necessary(token)
	tk = @@tokens[token]
	unless (tk[:running])
		if (tk["command"])
			cmd ="#{tk["command"]} " 
		else
			cmd = "#{@@config["webcam_command"]} &"
		end
		tk[:pid] = spawn(cmd)
		Process.detach(tk[:pid])
		tk[:running] = true
	end
end

def cleanup 
	@@tokens.each do |key, t|
		#PID+1 seems to be the right pid
		Process.kill("HUP", t[:pid] + 1) unless t[:pid].nil?

		File.delete(filename_for(key))
	end
end

def filename_for(token)
	tk = @@tokens[token]
	if tk["filename"].nil?
		"image.jpg"
	else
		tk["filename"]
	end
end

def main_url
	p @@config
	"/#{@@config['main_token']}.html"
end

# - SERVE METHODS
reload_config



get '/' do
	redirect(main_url)
end

get '/reload/:reload_token' do
	return status 403 unless reload_config_token_is_ok?(params[:reload_token])
	reload_tokens
	redirect(main_url)
end

get '/:token.html' do
	return status 403 unless token_valid?(params[:token], {ip: request.ip})
	start_if_necessary(params[:token])
	@@html_code.to_s.gsub("<TOKEN>", params[:token])
end

get '/:token/image.jpg' do
	return status 403 unless token_valid?(params[:token], {ip: request.ip})
	start_if_necessary(params[:token])
	f = File.read(filename_for(params[:token]))
	f.to_s
end


