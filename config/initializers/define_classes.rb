Rails.application.config.after_initialize do
  Role.load_role_classes
end
