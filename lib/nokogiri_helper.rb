require 'net/http'
require 'net/https'

module NokogiriHelper
  def page(page_url)
    response = Nokogiri::HTML(open(URI.escape(page_url)))
  rescue Errno::ENOENT, OpenURI::HTTPError => e
    nil
  end
  
  # Fetches page and returns redirect URL in location header
  def redirect_url(url_string)
    url = URI.parse(URI.escape(url_string))
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true if url.scheme == "https"
    req = Net::HTTP::Get.new(url.path, {'User-Agent' => 'Ruby'})
    response = https.request(req)
    response.header["location"]
  end

  extend self
end

class NokogiriHelperError < Exception; end
