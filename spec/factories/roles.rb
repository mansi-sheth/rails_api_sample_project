# == Schema Information
#
# Table name: roles
#
#  id         :bigint           not null, primary key
#  default    :boolean          default(FALSE), not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_roles_on_name  (name) UNIQUE
#
# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    default { false }

    # Default role factories
    factory :admin_role do
      name { Role::ADMIN }
      default { true }
    end

    factory :agent_role do
      name { Role::AGENT }
      default { true }
    end

    factory :requester_role do
      name { Role::REQUESTER }
      default { true }
    end
  end
end
