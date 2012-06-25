# Load server configuration YAML file
settings = {}
begin
  settings = YAML.load(File.read("#{Rails.root}/config/settings.yaml"))
rescue Errno::ENOENT
  # config/settings.yaml doesn't exist
end

# Set path to image magick
path = settings[:image_magick_path]

# See if the system knows
if path.nil?
  possible_path = File.dirname(`which identify`.chomp)
  path = possible_path unless possible_path == "."
end

# Check a couple places it may be
if path.nil?
  ["/opt/local/bin","/usr/bin"].each do |possible_path|
    path = possible_path if File.exists?(Pathname.new(possible_path) + "identify")
  end
end

# Warn and don't set paperclip path (hopefully it does the right thing)
if path.nil?
  puts "Unable to determine the path to image magick.  If Paperclip errors, set the path manually in config/initializers/paperclip.rb"
else
  # Paperclip.options[:image_magick_path] = path
  Paperclip.options[:command_path] = path
end