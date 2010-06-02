# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{activeresource}
  s.version = "3.0.0.beta"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Heinemeier Hansson"]
  s.date = %q{2010-02-04}
  s.description = %q{REST-model framework (part of Rails).}
  s.email = %q{david@loudthinking.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["CHANGELOG", "README", "examples/simple.rb", "lib/active_resource/base.rb", "lib/active_resource/connection.rb", "lib/active_resource/custom_methods.rb", "lib/active_resource/exceptions.rb", "lib/active_resource/formats/json_format.rb", "lib/active_resource/formats/xml_format.rb", "lib/active_resource/formats.rb", "lib/active_resource/http_mock.rb", "lib/active_resource/observing.rb", "lib/active_resource/railtie.rb", "lib/active_resource/railties/subscriber.rb", "lib/active_resource/schema.rb", "lib/active_resource/validations.rb", "lib/active_resource/version.rb", "lib/active_resource.rb"]
  s.homepage = %q{http://www.rubyonrails.org}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{activeresource}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{REST-model framework (part of Rails).}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, ["= 3.0.0.beta"])
      s.add_runtime_dependency(%q<activemodel>, ["= 3.0.0.beta"])
    else
      s.add_dependency(%q<activesupport>, ["= 3.0.0.beta"])
      s.add_dependency(%q<activemodel>, ["= 3.0.0.beta"])
    end
  else
    s.add_dependency(%q<activesupport>, ["= 3.0.0.beta"])
    s.add_dependency(%q<activemodel>, ["= 3.0.0.beta"])
  end
end
