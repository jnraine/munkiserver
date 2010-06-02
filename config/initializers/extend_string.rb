class String
  def each(&block)
    self.each_line(&block)
  end
  
  def from_plist
    Plist.parse_xml(self)
  end
end