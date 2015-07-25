require 'mini_magick'
def capture(width, height, device, filename)
	cmd = "imagesnap -w 0.75 -d \"#{device}\" #{filename}"
	puts cmd
	pid = Process.spawn(cmd)
	Process.wait(pid)

	image = MiniMagick::Image.open(filename)
	image.resize "#{width}x#{height}"
	image.write filename
end

def can_capture?
	system("which imagesnap > /dev/null")
end

def print_requirements
	puts "Please install imagesnap (you can install it via homebrew)"
end

def list_webcams
	`imagesnap -l`.split("\n")[1..-1]
end
