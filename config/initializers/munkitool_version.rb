if Munki::Application::MUNKI_TOOLS_AVAILABLE
  version_path = Pathname.new("/usr/local/munki/munkilib/version.plist")
  svn_version_path = Pathname.new("/usr/local/munki/munkilib/svnversion")
  
  munki_version = Plist::parse_xml(version_path)["CFBundleShortVersionString"]
  
  munki_build = File.new(svn_version_path, "r").gets.strip
  
  Munki::Application::MUNKITOOLS_VERSION = "#{munki_version} (#{munki_build})"
else
  Munki::Application::MUNKITOOLS_VERSION = "not installed"
end