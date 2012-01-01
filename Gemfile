# Edit this Gemfile to bundle your application's dependencies.
source 'http://gemcutter.org'

gem "rails", "3.0.10"
gem "sqlite3-ruby", :require => "sqlite3"
gem 'will_paginate', '~> 3.0'
gem "nokogiri"
gem "paperclip"
gem "client_side_validations"
gem "whenever"
gem "plist"
gem "cancan"
gem "highline"
gem "newrelic_rpm", :group => :production

group :development do
  gem "textmate_backtracer"
end

group :test, :development do
  gem "pry-rails"
  gem "rspec-rails", "~> 2.6"
  gem "capybara"
  gem "launchy"
  gem "guard-rspec"
  gem "guard-cucumber"
end

group :test do
  gem 'cucumber-rails'
  gem "factory_girl_rails"
  gem 'database_cleaner'
end
