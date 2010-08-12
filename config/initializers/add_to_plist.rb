# Added to make up for the lack of inclusion of the Plist::Emit module in the Hash and Array classes.
# Sometimes they appear to be extended, sometimes they don't.  This started to happen after updating
# to Ruby 1.9.2-rc2.  This is one of many fixes for the upgrade.  Once it started behaving properly,
# feel free to delete this file.

class Hash
  include Plist::Emit
end

class Array
  include Plist::Emit
end