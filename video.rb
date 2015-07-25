SECONDS_PER_SEGMENT = 10
PLAYLIST_LENGTH = 6

def video_streaming_enabled?
	@@config['video_capture']
end

def video_available?
	@@segment_ctr > 1
end

def start_video_capture
	FileUtils.rm_r "segments" if Dir.exist?("segments")
	FileUtils.mkdir "segments"
	Thread.new do
		loop do
			@@segment_ctr = @@segment_ctr + 1
			if @@segment_ctr > 10
				# cleanup
				File.delete(segment_filename(@@segment_ctr - 10))
			end 

			filename = segment_filename(@@segment_ctr)
			capture_video(filename, SECONDS_PER_SEGMENT)
		end
	end
end


def segment_filename(segment_id)
	"segments/video_#{segment_id}.mpg"
end

def video_playlist(from_segment, token, entries)
	s = "#EXTM3U\n"
	(from_segment-1..from_segment+entries).each do |i|
		s = s + "#EXTINF:#{SECONDS_PER_SEGMENT}, Video\n"
		s = s + "#{base_url}/#{token}/video_#{i}.mpg\n"
	end
	s
end
