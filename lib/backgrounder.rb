module Backgrounder
  def call_rake(task, options = {})
    options[:rails_env] ||= Rails.env
    args = options.map { |key, value| "#{key.to_s.upcase}='#{value}'" }
    system "rake #{task} #{args.join(' ')} --trace >> #{Rails.root}/log/rake.log &"
  end
  
  extend self
end