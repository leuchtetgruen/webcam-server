require 'optparse'
require 'net/http'
require 'json'

options = {port: 80}
OptionParser.new do |opts|
	opts.banner = "Usage: client.rb [options]"

	opts.on("--server host", String, "IP or hostname of server") do |host|
		options[:host] = host
	end

	opts.on("--port PORT", Integer, "Port of server") do |port|
		options[:port] = port 
	end

	opts.on("--secret S", String, "Secret for server") do |s|
		options[:secret] = s
	end

end.parse!

def base_url(options)
	"http://#{options[:host]}:#{options[:port]}"
end

cmd = ARGV[0].downcase
case cmd
when 'create-token'
	url = "#{base_url(options)}/access/create/restricted/#{options[:secret]}"
	res = Net::HTTP.get_response(URI.parse(url.to_s))
	if res.code.to_i == 200 then
		token = res.body
		bu =  "#{base_url(options)}/#{token}"
		puts "Webclient: #{bu}.html"
		puts "Image-URL: #{bu}/image.jpg"
	else
		puts "Error - maybe the secret is not right"
	end
when 'stats'
	url = "#{base_url(options)}/stats/#{options[:secret]}"
	res = Net::HTTP.get_response(URI.parse(url.to_s))
	if res.code.to_i == 200 then
		stats = JSON.parse(res.body)
		p stats
	else
		puts "Error - maybe the secret is not right"
	end
else
	puts "commands are create-token or stats"
end
