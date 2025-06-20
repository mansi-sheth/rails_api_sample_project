# frozen_string_literal: true

AdminUser.create!(email: 'admin@example.com', password: 'password') if Rails.env.development?
Setting.create_or_find_by!(key: 'min_version', value: '0.0')

# Create default roles
puts 'Creating default roles...'
Role.create_defaults
