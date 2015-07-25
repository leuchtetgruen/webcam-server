require 'fileutils'
def cleanup 
	FileUtils.rm_r "segments"
	system("killall ffmpeg")
end
at_exit { cleanup } 

require 'sinatra'
require 'json'

$: << "."
require "helper"
require "video.rb"


@@html_code = File.read("webcam.html")

@@config = {}
@@tokens = {}

@@segment_ctr = 0

@@mode = :picture


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

		if tk["ips"] then
			ret_val = tk["ips"].any? { |ip| opts[:ip].match(ip) }
		end

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

def width
	@@config['width'].nil? ? 640 : @@config['width'] 
end

def height
	@@config['height'].nil? ? 480 : @@config['height'] 
end

def webcam_name
	@@config['webcam_name'] ? @@config['webcam_name'] : list_webcams.first
end

def filename_for(token)
	tk = @@tokens[token]
	if tk["filename"].nil?
		"image.jpg"
	else
		tk["filename"]
	end
end

def record_local(token, res)
	path = @@config['record_path']
	unless path.nil?
		filename = "#{path}/#{token}_#{Time.new.to_i}.jpg"
		File.write(filename, res)
	end
end

def main_url
	if @@mode == :picture
		"/#{@@config['main_token']}.html"
	elsif @@mode == :video
		"/#{@@config['main_token']}.m3u8"
	end
end


# - SERVE METHODS
reload_config

require_platform_capture
unless can_capture?
	print_requirements
	exit
end

if ARGV.size > 0
	arg = ARGV.first.downcase
	if arg == "list"
		puts "List of devices\n"
		puts list_webcams
		exit
	end
	if arg == "video"
		@@mode = :video
	end
end

if video_streaming_enabled?
	unless can_capture_video?
		print_video_requirements
		exit
	end
	start_video_capture
end

set :port, @@config['port']
set :bind, "0.0.0.0"


configure do
	file = File.new("log/access.log", "a+")
	file.sync = true
	use Rack::CommonLogger, file
end


get '/' do
	redirect(main_url)
end

get '/reload/:reload_token' do
	return status 403 unless reload_config_token_is_ok?(params[:reload_token])
	reload_config
	redirect(main_url)
end

if @@mode == :picture 
	get '/:token.html' do
		return status 403 unless token_valid?(params[:token], {ip: request.ip})
		@@html_code.to_s.gsub("<TOKEN>", params[:token])
	end

	get '/:token/image.jpg' do
		return status 403 unless token_valid?(params[:token], {ip: request.ip})
		filename = filename_for(params[:token])
		w = params[:w] || width
		h = params[:h] || height
		capture(w, h, webcam_name, filename)
		res = File.read(filename).to_s
		record_local(params[:token], res)
		File.delete(filename)
		res
	end
end

# Video URLS
if @@mode == :video
	get '/:token.m3u8' do
		return status 404 unless video_streaming_enabled?
		return status 503 unless video_available?
		return status 403 unless token_valid?(params[:token], {ip: request.ip})
		video_playlist(@@segment_ctr, params[:token], params[:size].to_i)
	end

	get '/:token/video_:segment.mpg' do
		return status 404 unless video_streaming_enabled?
		return status 403 unless token_valid?(params[:token], {ip: request.ip})
		res = File.read(segment_filename(params[:segment])).to_s
		res
	end

	get '/:token/:sfrom/:sto/video.mpg' do
		return status 404 unless video_streaming_enabled?
		return status 403 unless token_valid?(params[:token], {ip: request.ip})
		from = params[:sfrom].to_i
		to = params[:sto].to_i
		out = "video_#{from}_#{to}.mpg"
		success = video_concatenate(from, to, out)
		
		return status 404 unless success
		
		res = File.read(out).to_s
		File.delete(out)
		res
	end

	get '/:token/last_seconds/:seconds.mpg' do
		return status 404 unless video_streaming_enabled?
		return status 403 unless token_valid?(params[:token], {ip: request.ip})
		seconds = params[:seconds].to_i
		n_segments = (seconds.to_f / SECONDS_PER_SEGMENT.to_f).to_i
		from = @@segment_ctr - n_segments
		to = @@segment_ctr - 1
		redirect("/#{params[:token]}/#{from}/#{to}/video.mpg")
	end

	get '/:token/last_minutes/:minutes.mpg' do
		redirect("/#{params[:token]}/last_seconds/#{params[:minutes].to_i*60}.mpg")
	end
end

