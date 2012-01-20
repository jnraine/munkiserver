class String
  def each(&block)
    self.each_line(&block)
  end
  
  def from_plist
    begin
      Plist.parse_xml(self)
    rescue RuntimeError
      return self #return nothign not a valide plist string
    rescue NoMethodError
      return self #return nothing invalide syntax or nil object
    rescue Errno::EISDIR
      return self #only happen if you have a string "test", not sure why
    end
  end
  
  # Convert string from whatever encoding to UTF-8, covering corner cases
  def to_utf8
    if defined?(String::Encoding)
      begin
        self.encode("UTF-8")
      rescue Encoding::UndefinedConversionError => e
        forced = self.force_encoding("UTF-8")
        if forced.valid_encoding?
          forced
        else
          raise EncodingError("Unable to convert string from #{self.encoding} to UTF-8. The encode method threw " + e + " and forced encoding failed to produce a valid string encoding")
        end
      end
    else
      # This seems to be ruby 1.8.x, use iconv instead
      ::Iconv.conv('UTF-8//IGNORE', 'UTF-8', self + ' ')[0..-2]
    end
  end

  # Compare a version string (e.g., "7.0.1.2") with self.
  # Returns 1, 0, -1: greater than, equal, less than, respectively.  Similar to <=>.
  def version_string_comparison(string)
    unless string.instance_of?(String)
      raise ArgumentError.new("Must pass string for version string comparison. Got a #{string.class} instance.")
    end

    # Convert to array of ints (if possible), snipping off any guff
    f_split = self.gsub(/(\.0)+$/,'').split(".").map { |e| e.match(/^\d+$/) ? e.to_i : e }
    s_split = string.gsub(/(\.0)+$/,'').split(".").map { |e| e.match(/^\d+$/) ? e.to_i : e }
    
    # Compare the array elements
    i = 0
    comparison_results = []
    while(i < f_split.length or i < s_split.length) do
      if f_split[i].nil? or s_split[i].nil?
        # One results is nil
        comparison_results << 1 if f_split[i]
        comparison_results << -1 if s_split[i]
      elsif f_split[i].instance_of?(String) or s_split[i].instance_of?(String)
        # Compare as strings
        comparison_results << f_split[i].to_s.<=>(s_split[i].to_s)
      else
        # Compare as integers
        comparison_results << f_split[i].<=>(s_split[i])
      end
      i += 1
    end
    
    # Return comparison result, if strings not equal
    comparison_results.each do |comparison_result|
      return comparison_result unless comparison_result == 0
    end
    # If we made it here, they are equal
    return 0
  end
end