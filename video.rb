require 'tempfile'

SECONDS_PER_SEGMENT = 10
PLAYLIST_LENGTH = 6
KEEP_SEGMENTS = 100

def video_streaming_enabled?
	@@mode == :video
end

def video_available?
	@@segment_ctr > 1
end

def keep_segments
	ret = (@@config['keep_minutes'].to_i * 60) / SECONDS_PER_SEGMENT
	(ret == 0) ? KEEP_SEGMENTS : ret
end


def start_video_capture
	FileUtils.rm_r "segments" if Dir.exist?("segments")
	FileUtils.mkdir "segments"
	Thread.new do
		loop do
			@@segment_ctr = @@segment_ctr + 1
			if @@segment_ctr > keep_segments
				# cleanup
				File.delete(segment_filename(@@segment_ctr - keep_segments))
			end 

			filename = segment_filename(@@segment_ctr)
			capture_video(filename, SECONDS_PER_SEGMENT)
		end
	end
end


def segment_filename(segment_id)
	"segments/video_#{segment_id}.mpg"
end

def video_playlist(from_segment, token, entries=0)
	entries = PLAYLIST_LENGTH if entries == 0
	s = "#EXTM3U\r\n"
	(from_segment-1..from_segment+entries).each do |i|
		s = s + "#EXTINF:#{SECONDS_PER_SEGMENT}, Video\r\n"
		s = s + "#{base_url}/#{token}/video_#{i}.mpg\r\n"
	end
	s
end

def video_concatenate(from_segment, to_segment, outputfile)
	files = (from_segment..to_segment).map do |i|
		"file '#{segment_filename(i)}'"
	end
	File.write("playlist", files.join("\n"))
	
	puts "Converting"
	cmd = "ffmpeg -f concat -i playlist -c copy #{outputfile} > /dev/null 2>&1"
	pid = Process.spawn(cmd)
	Process.wait(pid)
	File.delete("playlist")

	puts "Done"
	true
end

