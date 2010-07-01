#!/usr/bin/env ruby
# Must be called from Rails.root
# Open VERSION file
path = `pwd`.chomp + "/config/VERSION"
version = File.read(path)
a = version.split(".")
a[a.length - 1] = a[a.length - 1].to_i + 1
version = a.join(".")
File.open(path, 'w') {|f| f.write(version) }
puts "#{version}"