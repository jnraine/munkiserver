#!/usr/bin/ruby
# 
#  upload_report.rb
#  Munki Server Client postflight script uses curl to post the latest ManagedInstallReport.plist
#  
#  Created by Jordan Raine and Brian Warsing on 2011-03-28.
#  Copyright 2011 Simon Fraser University. All rights reserved.
#  Tue Apr  5 08:37:34 PDT 2011
#  Version 0.1.3

require 'cgi'
require 'pathname'
require 'time'
require 'osx/cocoa'

include OSX

BUNDLE_ID = "ManagedInstalls"

def bundle_pref_by_key(key)
  value = CFPreferencesCopyAppValue(key, BUNDLE_ID)
  return "" if value.nil?
  value.to_ruby
end

def client_identifier
  if @client_identifier.nil?
    client_identifier = bundle_pref_by_key("ClientIdentifier")
    begin
      id = client_identifier.match(/(.*)(\.plist)/)[1].sub("computers/", "")
    rescue => error
      puts error.message + "\n"
      puts "ClientIdentifier key, invalid string: #{client_identifier}"
      exit 1
    end
    @client_identifier = id
  end
  @client_identifier
end

def munkiserver_url
  bundle_pref_by_key("ManifestURL")
end

def cacert_file
  bundle_pref_by_key("SoftwareRepoCACertificate")
end

def checkin_url
  munkiserver_url + "/checkin/" + client_identifier
end

def managed_install_dir
  path = bundle_pref_by_key("ManagedInstallDir")
  path ||= "/Library/Managed Installs"
  Pathname.new(path)
end

def latest_managed_install_report_path
  managed_install_dir + "ManagedInstallReport.plist"
end

def ssl_option
  cacert_file == "" ? "" : "--cacert \"#{cacert_file}\""
end

def debug?
  ARGV[0] == "debug"
end

def test?
  ARGV[0] == "test"
end

# Generates a system_profile plist and returns the path to it
def system_profiler_plist
  tmp_path = "/tmp/system_profiler_#{rand(1001)}.plist"
  `/usr/sbin/system_profiler -xml SPHardwareDataType SPSoftwareDataType SPPrintersDataType > #{tmp_path}`
  tmp_path
end

post_command = "/usr/bin/curl #{ssl_option} --form \"managed_install_report_plist=@#{latest_managed_install_report_path}\" --form \"system_profiler_plist=@#{system_profiler_plist}\" #{checkin_url}"

if test? or debug?
  puts  post_command
else
  `#{post_command}`
end