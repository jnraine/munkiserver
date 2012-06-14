module Backgrounder
  LOG_PATH = "#{Rails.root}/log/backgrounder.log"
  
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |key, value| "#{key.to_s.upcase}='#{value}'" }
    system "rake #{task} #{args.join(' ')} --trace >> #{LOG_PATH} 2>&1 &"
  end
  
  extend self
end