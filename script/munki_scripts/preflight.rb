#!/usr/bin/ruby

require 'osx/cocoa'
include OSX

MAC_ADDRESS = `ifconfig en0 | awk '/ether/ {print $2}'`.strip
BUNDLE_ID = "ManagedInstalls"

def set_preference(key, value)
  CFPreferencesSetValue(key, value, BUNDLE_ID, KCFPreferencesAnyUser, KCFPreferencesCurrentHost)
end

def save_preferences
  CFPreferencesSynchronize(BUNDLE_ID, KCFPreferencesAnyUser, KCFPreferencesCurrentHost)
end

client_identifier = MAC_ADDRESS + ".plist"
set_preference("ClientIdentifier", client_identifier)
save_preferences