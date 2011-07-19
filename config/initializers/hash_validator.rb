class HashValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    unless value.class == Hash
      record.errors.add attribute, 'must be a valid hash object'
    end
  end
end