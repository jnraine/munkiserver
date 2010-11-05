if File.exists?("/usr/bin/hdiutil") and File.directory?("/usr/local/munki")
  Munki::Application::MUNKI_TOOLS_AVAILABLE = true
else
  Munki::Application::MUNKI_TOOLS_AVAILABLE = false
end