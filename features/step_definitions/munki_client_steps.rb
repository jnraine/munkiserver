Given /^a munki client$/ do
  @client = Factory.create(:computer)
end

When /^the client requests its primary manifest$/ do
  visit computer_manifest_path(@client.mac_address)
end

Then /^the client is given a valid manifest$/ do
  page.has_content? "managed_installs"
end