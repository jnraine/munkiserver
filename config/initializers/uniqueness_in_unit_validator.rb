# To be used only with package version attribute until package branch is unique
# to a unit as well.
class UniquenessInUnitValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    return if value.blank?
    packages = Package.unit(record.unit).where(:package_branch_id => record.package_branch_id)
    if packages.map(&:version).include?(value)
      record.errors.add attribute, 'must be unique within this unit'
    end
  end
end