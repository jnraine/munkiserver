class PlistArrayValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    unless value.class == Array
      record.errors.add attribute, 'must be a valid plist array object'
    end
  end
end