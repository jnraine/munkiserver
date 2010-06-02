# A Ruby-wrapper for the command line utility plutil
# Really inefficient but it does the job
module Plutil
  extend self
  
  require 'FileUtils'
  
  PLUTIL = "/usr/bin/plutil"
  
  # Returns boolean if passed plist string is valid
  def valid?(plist_string)
    self.validate(plist_string)[:valid]
  end
  
  # Returns hash with results of validation
  # {:valid => true/false,
  #  :error => "some string"}
  def validate(plist_string)
    tmp_path = self.generate_random_path
    log_path = self.generate_random_path
    File.open(tmp_path, 'w') {|f| f.write(plist_string) }
    valid = system("#{PLUTIL} -lint #{tmp_path} > #{log_path}")
    FileUtils.rm(tmp_path)
    {:valid => valid, :error => parse_log_file(log_path)}
  end
  
  def parse_log_file(log_path)
    s = File.read(log_path)
    s = s.match(/(rbplutil-\d+\.plist: )(.+)(\n)/)[2]
    FileUtils.rm(log_path)
    if s.nil?
      nil
    else
      s
    end
  end
  
  def generate_random_path
    "/tmp/rbplutil-#{rand(10001)}.plist"
  end
end