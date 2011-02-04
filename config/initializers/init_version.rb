# 
# Initialize version number using config/VERSION and git commit sha (if available)
# 

# Current version
version = nil
begin
  version = File.read("#{Rails.root}/config/VERSION")
rescue Errno::ENOENT
  version = ""
end
# Append git commit sha
common_git_paths = %w[/usr/local/bin/git /usr/local/git/bin/git /opt/local/bin/git]
git = ""
common_git_paths.each do |p|
  if File.exist?(p)
    git = p
    break
  end
end
git_sha = " (" + `cd #{Rails.root} && #{git} rev-parse --short HEAD`.chomp + ")" if git.present?

Munki::Application::VERSION = (git_sha.present?) ? version + git_sha : version