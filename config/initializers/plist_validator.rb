class PlistValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    begin
      unless value.from_plist.instance_of?(Array)
        record.errors.add attribute, 'must be a valid plist object'
      end
    rescue NoMethodError
        record.errors.add attribute, 'must be a valid plist object'
    end
  end
end