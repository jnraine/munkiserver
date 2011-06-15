class String
  def each(&block)
    self.each_line(&block)
  end
  
  def from_plist
    Plist.parse_xml(self)
  end
  
  # Convert string from whatever encoding to UTF-8, covering corner cases
  def to_utf8
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
  end
end