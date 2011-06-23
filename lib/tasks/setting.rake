namespace :setting do
  desc "create a new settings.yaml file optional arguments rake setup:create[hostname] default localhost:3000"
  task :create, :arg1 do |t, args|
    #if settings.yaml file doesn't exists and arguments is given
    if !args.arg1.nil? and !File.exists?("config/settings.yaml")
       h = {}
        File.open( "config/settings.yaml", "w" ) do |file|
         h[:action_mailer] = {:host => "#{args.arg1}" }
         file.write(h.to_yaml)
        end
   # open the existing settings yaml and overwrite the host key
   elsif !args.arg1.nil? and File.exists?("config/settings.yaml")
     settings = nil
     settings = YAML.load(File.read("config/settings.yaml"))
     settings[:action_mailer][:host] = "#{args.arg1}"
     File.open( "config/settings.yaml", "w" ) do |file|
       file.write(settings.to_yaml)
     end
   #if settings yaml doens't exists and no args is given then default to machine host name
   elsif args.arg1.nil? and !File.exists?("config/settings.yaml")
     h = {}
     File.open( "config/settings.yaml", "w" ) do |file|
       h[:action_mailer] = {:host => "localhost:3000" }
       file.write(h.to_yaml)
     end
   else 
     puts "settings.yaml file is already exists"
   end
        
  end
end