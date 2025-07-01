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

describe User do
  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider) }

    context 'when was created with regular login' do
      subject { build(:user) }

      it { is_expected.to validate_uniqueness_of(:email).case_insensitive.scoped_to(:provider) }
      it { is_expected.to validate_presence_of(:email) }
    end
  end

  describe 'associations' do
    # Classification: High Importance
    # Type: Happy Path
    # Scenario: User has many user_roles association
    # Impact: Data relationships
    it { is_expected.to have_many(:user_roles).dependent(:destroy) }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: User has many roles through user_roles
    # Impact: Data relationships
    it { is_expected.to have_many(:roles).through(:user_roles) }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: User accepts nested attributes for user_roles
    # Impact: Data management
    it { is_expected.to accept_nested_attributes_for(:user_roles).allow_destroy(true) }
  end

  context 'when was created with regular login' do
    let!(:user) { create(:user) }
    let(:full_name) { user.full_name }

    it 'returns the correct name' do
      expect(full_name).to eq(user.username)
    end
  end

  context 'when user has first_name' do
    let!(:user) { create(:user, first_name: 'John', last_name: 'Doe') }

    it 'returns the correct name' do
      expect(user.full_name).to eq('John Doe')
    end
  end

  describe '.from_social_provider' do
    context 'when user does not exists' do
      let(:params) { attributes_for(:user) }

      it 'creates the user' do
        expect {
          described_class.from_social_provider('provider', params)
        }.to change(described_class, :count).by(1)
      end
    end

    context 'when the user exists' do
      let!(:user)  { create(:user, provider: 'provider', uid: 'user@example.com') }
      let(:params) { attributes_for(:user).merge('id' => 'user@example.com') }

      it 'returns the given user' do
        expect(described_class.from_social_provider('provider', params))
          .to eq(user)
      end
    end
  end

  describe 'role management' do
    let(:user) { create(:user) }
    let(:role1) { create(:role, name: 'Manager') }
    let(:role2) { create(:role, name: 'Developer') }
    let(:role3) { create(:role, name: 'Admin') }

    describe '#role_ids' do
      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Role IDs virtual attribute
      # Impact: User role management
      it 'has role_ids virtual attribute' do
        expect(user).to respond_to(:role_ids)
        expect(user).to respond_to(:role_ids=)
      end
    end

    describe '#sync_roles' do
      context 'when role_ids is set' do
        # Classification: High Importance
        # Type: Happy Path
        # Scenario: Syncing roles with role_ids array
        # Impact: User role management
        it 'syncs roles based on role_ids' do
          user.role_ids = [role1.id, role2.id]
          user.save!

          expect(user.roles).to match_array([role1, role2])
          expect(user.user_roles.count).to eq(2)
        end

        # Classification: High Importance
        # Type: Edge Case
        # Scenario: Updating role_ids removes old roles
        # Impact: User role management
        it 'removes old roles when role_ids change' do
          user.role_ids = [role1.id, role2.id]
          user.save!

          user.role_ids = [role2.id, role3.id]
          user.save!

          expect(user.roles).to match_array([role2, role3])
          expect(user.user_roles.count).to eq(2)
        end

        # Classification: High Importance
        # Type: Edge Case
        # Scenario: Empty role_ids removes all roles
        # Impact: User role management
        it 'removes all roles when role_ids is empty' do
          user.role_ids = [role1.id, role2.id]
          user.save!

          user.role_ids = []
          user.save!

          expect(user.roles).to be_empty
          expect(user.user_roles.count).to eq(0)
        end

        # Classification: High Importance
        # Type: Edge Case
        # Scenario: String role IDs are converted to integers
        # Impact: User role management
        it 'handles string role_ids by converting to integers' do
          user.role_ids = [role1.id.to_s, role2.id.to_s]
          user.save!

          expect(user.roles).to match_array([role1, role2])
        end

        # Classification: High Importance
        # Type: Edge Case
        # Scenario: Duplicate role_ids are handled correctly
        # Impact: User role management
        it 'handles duplicate role_ids without creating duplicates' do
          user.role_ids = [role1.id, role1.id, role2.id]
          user.save!

          expect(user.roles).to match_array([role1, role2])
          expect(user.user_roles.count).to eq(2)
        end
      end

      context 'when role_ids is not set' do
        # Classification: High Importance
        # Type: Edge Case
        # Scenario: No sync when role_ids is not provided
        # Impact: User role management
        it 'does not sync roles if role_ids is not set' do
          create(:user_role, user: user, role: role1)
          original_roles = user.roles.to_a

          user.update!(first_name: 'Updated')

          expect(user.roles.to_a).to eq(original_roles)
        end
      end

      context 'when role_ids is not an array' do
        # Classification: High Importance
        # Type: Edge Case
        # Scenario: Invalid role_ids type handling
        # Impact: User role management
        it 'does not sync roles if role_ids is not an array' do
          create(:user_role, user: user, role: role1)
          original_roles = user.roles.to_a

          user.role_ids = 'invalid'
          user.save!

          expect(user.roles.to_a).to eq(original_roles)
        end
      end
    end

    describe '#as_json' do
      before do
        user.role_ids = [role1.id, role2.id]
        user.save!
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: JSON serialization includes roles
      # Impact: API data delivery
      it 'includes roles in JSON representation' do
        json = user.as_json

        expect(json).to have_key('roles')
        expect(json['roles']).to be_an(Array)
        expect(json['roles'].length).to eq(2)
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Roles have correct attributes in JSON
      # Impact: API data delivery
      it 'includes role id and name in JSON' do
        json = user.as_json

        role_data = json['roles']
        expect(role_data.map { |r| r['id'] }).to match_array([role1.id, role2.id])
        expect(role_data.map { |r| r['name'] }).to match_array([role1.name, role2.name])
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Only specific role attributes are included
      # Impact: API data delivery
      it 'only includes id and name for roles' do
        json = user.as_json

        role_data = json['roles'].first
        expect(role_data.keys).to match_array(['id', 'name'])
        expect(role_data).not_to have_key('created_at')
        expect(role_data).not_to have_key('updated_at')
        expect(role_data).not_to have_key('default')
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Custom options are merged with role inclusion
      # Impact: API data delivery
      it 'merges custom options with role inclusion' do
        json = user.as_json(only: [:id, :email])

        expect(json).to have_key('id')
        expect(json).to have_key('email')
        expect(json).to have_key('roles')
        expect(json).not_to have_key('first_name')
      end
    end
  end
end
