def os_range(major, minor, point_range = 0..0)
  point_range.collect{|point|
    [os_version_for_value(major,minor,point),  os_version_for_display(major,minor,point)]
  }.reverse
end

def os_version_for_display(major, minor, point)
   "#{major}.#{minor}.#{point}"
end

def os_version_for_value(major,minor,point)
  if point != 0
    "#{major}.#{minor}.#{point}"
  else
    "#{major}.#{minor}"
  end
end