def capture(width, height, device, filename)
	#TODO device
	cmd = "fswebcam -F 3 -r #{width}x#{height} #{filename}"
	puts cmd
	pid = Process.spawn(cmd)
	Process.wait(pid)
end

def can_capture?
	system("which fswebcam> /dev/null")
end

def print_requirements
	puts "Please install fswebcam"
end

def list_webcams
	["Camera 1"]
end
