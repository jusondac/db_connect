class Role < ApplicationRecord
  after_commit { Role.define_role_classes }

  def self.define_role_classes
    Role.find_each do |role|
      class_name = role.name.capitalize
      Object.const_set(class_name, Class.new do
        # Store the role name as a class method
        define_singleton_method :role_name do
          role.name
        end
      end)
    end
  end

  def self.load_role_classes
    define_role_classes
  end
end
