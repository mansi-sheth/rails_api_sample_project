# frozen_string_literal: true

# == Schema Information
#
# Table name: roles
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  default    :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_roles_on_name  (name) UNIQUE
#
class Role < ApplicationRecord
  # Associations
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  
  # Callbacks
  before_destroy :ensure_not_default

  # Default roles
  ADMIN = 'Admin'
  AGENT = 'Agent'
  REQUESTER = 'Requester'

  # Scopes
  scope :default, -> { where(default: true) }
  scope :custom, -> { where(default: false) }

  # Class methods
  def self.default_roles
    [ADMIN, AGENT, REQUESTER]
  end

  # Create default roles if they don't exist
  def self.create_defaults
    default_roles.each do |role_name|
      find_or_create_by!(name: role_name) do |role|
        role.default = true
      end
    end
  end

  private

  def ensure_not_default
    if default?
      errors.add(:base, 'Cannot delete a default role')
      throw :abort
    end
  end
end
