def platform
	RUBY_PLATFORM.downcase
end

def linux?
	platform.include? "linux"
end

def osx?
	platform.include? "darwin"
end

def windows?
	platform.include? "windows"
end

def require_platform_capture
	require "osx_capture" if osx?
	require "linux_capture" if linux?
	require "windows_capture" if windows?
end
