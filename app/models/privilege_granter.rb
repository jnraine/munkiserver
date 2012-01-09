module PrivilegeGranter
  def self.unit_specific_privilege_groups
    [:computers, :computer_groups, :bundles, :user_groups, :packages, :permissions]
  end
  
  # ===================
  # = Computer Groups =
  # ===================
  def read_computer_groups(unit_ids)
    can :read, ComputerGroup, :unit_id => unit_ids
  end

  def modify_computer_groups(unit_ids)
    can [:update, :environment_change], ComputerGroup, :unit_id => unit_ids
  end

  def create_computer_groups(unit_ids)
    can :create, ComputerGroup, :unit_id => unit_ids
  end

  def destroy_computer_groups(unit_ids)
    can :destroy, ComputerGroup, :unit_id => unit_ids
  end

  # ===========
  # = Bundles =
  # ===========
  def read_bundles(unit_ids)
    can :read, Bundle, :unit_id => unit_ids
  end

  def modify_bundles(unit_ids)
    can [:update, :environment_change], Bundle, :unit_id => unit_ids
  end

  def create_bundles(unit_ids)
    can :create, Bundle, :unit_id => unit_ids
  end

  def destroy_bundles(unit_ids)
    can :destroy, Bundle, :unit_id => unit_ids
  end

  # =============
  # = Computers =
  # =============
  def read_computers(unit_ids)
    can [:read, :download, :update_warranty], Computer, :unit_id => unit_ids
    can :read, ManagedInstallReport
  end

  def modify_computers(unit_ids)
    can [:update, :edit_multiple, :update_multiple, :environment_change], Computer, :unit_id => unit_ids
  end

  def create_computers(unit_ids)
    can [:create, :import, :create_import], Computer, :unit_id => unit_ids
  end

  def destroy_computers(unit_ids)
    can :destroy, Computer, :unit_id => unit_ids
  end
  
  # ============
  # = Packages =
  # ============
  def read_packages(unit_ids)
    can [:read, :download, :check_for_updates, :index_shared], Package, :unit_id => unit_ids
  end

  def modify_packages(unit_ids)
    can [:update, :environment_change, :edit_multiple, :update_multiple], Package, :unit_id => unit_ids
  end

  def create_packages(unit_ids)
    can [:create, :import_shared, :import_multiple_shared], Package, :unit_id => unit_ids
  end

  def destroy_packages(unit_ids)
    can :destroy, Package, :unit_id => unit_ids
  end
  
  # ===============
  # = Permissions =
  # ===============
  def read_permissions(unit_ids)
    can [:read, :edit], Permission, :unit_id => unit_ids
  end

  def modify_permissions(unit_ids)
    can [:update, :destroy], Permission, :unit_id => unit_ids
  end
  
  def read_system_permissions(unit_ids)
    can [:read, :edit], Permission, :unit_id => nil
  end
  
  def modify_system_permissions(unit_ids)
    can [:update, :destroy], Permission, :unit_id => nil
  end

  # =========
  # = Users =
  # =========
  def read_users(unit_ids)
    can :read, User
  end

  def modify_users(unit_ids)
    can :update, User
  end

  def create_users(unit_ids)
    can :create, User
  end

  def destroy_users(unit_ids)
    can :destroy, User
  end

  # =========
  # = Units =
  # =========
  def read_units(unit_ids)
    can :read, Unit
  end

  def modify_units(unit_ids)
    can :update, Unit
  end

  def create_units(unit_ids)
    can :create, Unit
  end

  def destroy_units(unit_ids)
    can :destroy, Unit
  end

  # ===============
  # = User Groups =
  # ===============
  def read_user_groups(unit_ids)
    can :read, UserGroup, :unit_id => unit_ids
  end

  def modify_user_groups(unit_ids)
    can [:update, :environment_change], UserGroup, :unit_id => unit_ids
  end

  def create_user_groups(unit_ids)
    can :create, UserGroup, :unit_id => unit_ids
  end

  def destroy_user_groups(unit_ids)
    can :destroy, UserGroup, :unit_id => unit_ids
  end
end