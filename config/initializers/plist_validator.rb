class PlistValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    begin
      if value.from_plist.instance_of?(String)
        record.errors.add attribute, 'must be a valid plist string'
      end
    rescue NoMethodError
        record.errors.add attribute, 'must be a valid plist string'
    end
  end
end