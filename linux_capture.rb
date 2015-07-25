def capture(width, height, device, filename)
	#TODO device
	cmd = "fswebcam -F 3 -r #{width}x#{height} #{filename} > /dev/null 2>&1"
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

def capture_video(filename, seconds)
	cmd = "ffmpeg -f v4l2 -i /dev/video0 -t #{seconds} #{filename} > /dev/null 2>&1"
	puts cmd
	pid = Process.spawn(cmd)
	Process.wait(pid)
end

def can_capture_video?
	system("which ffmpeg > /dev/null")
end

def print_video_requirements
	puts "Please install fmpeg via homebrew. Take care that the qtkit codec is also installed"
end
