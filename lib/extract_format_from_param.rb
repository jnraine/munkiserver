# 
# Extracts the format from a request parameter.  In the case where a request
# parameter next to a request :format parameter may contain a space, it is 
# difficult to match your parameter accurately without selecting the format
# parameter as well.  Instead of matching carefully on the parameter, match
# everything (/.+/) and then this "constraint" will pull the format out of
# the parameter and add it to the request for you. Sort of a mis-use of a 
# constraint, but awfully helpful in this situation. Here is an example of 
# how it works:
# 
# In your routes file:
# constraints({:id => /.+/}) do
#   match '/:controller/:action/:id(.:format)', :constraint => ExtractFormatFromParam.new(:id)
# end
# 
# A request comes in to: "/post/edit/my.great.post.json".
# 
# The params looks like this: 
# {:controller => "post", :action => "edit", :id => "my.great.post.json"}
# After ExtractFormatFromParam runs, the params look like this: 
# {:controller => "post", :action => "edit", :id => "my.great.post", :format => "json"}
# 
class ExtractFormatFromParam
  def initialize(param_key)
    @param_key = param_key.to_s
  end
  
  def matches?(request)
    adjust_param(request)
    true
  end

  def adjust_param(request)
    format = extract_format(request,@param_key)
    if format.present?
      request.params["format"] = format
      request.params[@param_key] = request.params[@param_key].sub(/\.#{format}$/,'')
    end
  end
  
  def extract_format(request,param_key)
    value = request.params[param_key]
    if value.present? and match_data = value.match(format_pattern)
      match_strings = match_data.to_a.delete_if {|string| string.blank? }
      match_strings.last
    end
  end
  
  def format_pattern
    acceptable_formats = %w{html json xml plist}
    regex_string = "/"
    acceptable_formats.each_with_index do |acceptable_format,i|
      regex_string += "\\.#{acceptable_format}$"
      regex_string += "|" unless acceptable_format == acceptable_formats.last
    end
    regex_string += "/"
    eval(regex_string)
  end
end