# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  allow_password_change  :boolean          default(FALSE), not null
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  first_name             :string           default("")
#  last_name              :string           default("")
#  username               :string           default("")
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  provider               :string           default("email"), not null
#  uid                    :string           default(""), not null
#  tokens                 :json
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  # Associations
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  validates :uid, uniqueness: { scope: :provider }

  attribute :impersonated_by, :integer

  # Accept nested attributes for roles
  accepts_nested_attributes_for :user_roles, allow_destroy: true
  attr_accessor :role_ids

  before_validation :init_uid
  after_save :sync_roles, if: :role_ids

  RANSACK_ATTRIBUTES = %w[id email first_name last_name username sign_in_count current_sign_in_at
                          last_sign_in_at current_sign_in_ip last_sign_in_ip provider uid
                          created_at updated_at].freeze

  def self.from_social_provider(provider, user_params)
    where(provider:, uid: user_params['id']).first_or_create! do |user|
      user.password = Devise.friendly_token[0, 20]
      user.assign_attributes user_params.except('id')
    end
  end

  def full_name
    return username if first_name.blank?

    "#{first_name} #{last_name}"
  end

  # Serialize roles in the JSON response
  def as_json(options = {})
    super(options.merge(
      include: {
        roles: { only: [:id, :name] }
      }
    ))
  end

  private

  def init_uid
    self.uid = email if uid.blank? && provider == 'email'
  end

  # Sync roles based on role_ids attribute
  def sync_roles
    return unless role_ids.is_a?(Array)

    # Convert string IDs to integers
    role_ids_array = role_ids.map(&:to_i)
    
    # Remove roles that are not in the new role_ids
    user_roles.where.not(role_id: role_ids_array).destroy_all
    
    # Add new roles
    role_ids_array.each do |role_id|
      user_roles.find_or_create_by!(role_id: role_id)
    end
  end
end
