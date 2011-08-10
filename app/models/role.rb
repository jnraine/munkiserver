class Role < ActiveRecord::Base

has_many :assignments
has_many :users, :through => :assignments
validates_presence_of :name
validates_uniqueness_of :name, :message => "must be unique"

def self.find_by_sym(sym = nil)
  roles = self.all.collect!{|r| r if r.to_sym == sym.to_sym}.compact!
  roles.first if roles
end

def self.method_missing(meth, *args, &block)
  role = Role.find_by_sym(meth)
  role.present? ? role : super
end

def self.current_role(user, unit)
  if user.present? 
    if unit.present?
      assign = Assignment.find(:first, conditions: {user_id: user.id, unit_id: unit.id})
      assign.role if assign.present?
    else
      user.roles.first
    end
  end
end

def to_sym
  name.downcase.tr(' ', '_').to_sym
end

def to_s
  name
end

end
