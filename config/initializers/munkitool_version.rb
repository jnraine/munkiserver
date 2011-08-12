if Munki::Application::MUNKI_TOOLS_AVAILABLE
  Munki::Application::MUNKITOOLS_VERSION = `/usr/local/munki/makepkginfo -V`
else
  Munki::Application::MUNKITOOLS_VERSION = "not installed"
end