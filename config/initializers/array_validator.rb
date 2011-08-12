class ArrayValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    unless value.class == Array
      record.errors.add attribute, 'must be a valid array object'
    end
  end
end