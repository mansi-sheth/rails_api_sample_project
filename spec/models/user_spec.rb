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
  describe 'associations' do
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:roles).through(:user_roles) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_uniqueness_of(:uid).scoped_to(:provider) }

    context 'when was created with regular login' do
      subject { build(:user) }

      it { is_expected.to validate_uniqueness_of(:email).case_insensitive.scoped_to(:provider) }
      it { is_expected.to validate_presence_of(:email) }
    end
  end

  describe 'nested attributes' do
    it { should accept_nested_attributes_for(:user_roles).allow_destroy(true) }
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
    let(:admin_role) { create(:admin_role) }
    let(:agent_role) { create(:agent_role) }

    describe 'role assignment' do
      it 'can be assigned multiple roles' do
        user.roles << admin_role
        user.roles << agent_role
        
        expect(user.roles).to contain_exactly(admin_role, agent_role)
      end
    end

    describe '#sync_roles' do
      context 'when role_ids is set' do
        it 'syncs roles based on role_ids array' do
          user.role_ids = [admin_role.id, agent_role.id]
          user.save!
          
          expect(user.roles).to contain_exactly(admin_role, agent_role)
        end

        it 'removes roles not in role_ids' do
          user.roles << admin_role
          user.roles << agent_role
          
          user.role_ids = [admin_role.id]
          user.save!
          
          expect(user.roles).to contain_exactly(admin_role)
        end

        it 'handles string IDs correctly' do
          user.role_ids = [admin_role.id.to_s, agent_role.id.to_s]
          user.save!
          
          expect(user.roles).to contain_exactly(admin_role, agent_role)
        end

        it 'handles empty role_ids array' do
          user.roles << admin_role
          
          user.role_ids = []
          user.save!
          
          expect(user.roles).to be_empty
        end

        it 'avoids duplicate role assignments' do
          user.roles << admin_role
          
          user.role_ids = [admin_role.id, admin_role.id]
          user.save!
          
          expect(user.roles.count).to eq(1)
          expect(user.roles).to contain_exactly(admin_role)
        end
      end

      context 'when role_ids is not set' do
        it 'does not modify existing roles' do
          user.roles << admin_role
          original_roles = user.roles.to_a
          
          user.update!(first_name: 'Updated')
          
          expect(user.roles).to match_array(original_roles)
        end
      end

      context 'when role_ids is not an array' do
        it 'does not sync roles' do
          user.roles << admin_role
          
          user.role_ids = 'invalid'
          user.save!
          
          expect(user.roles).to contain_exactly(admin_role)
        end
      end
    end
  end

  describe '#as_json' do
    let(:user) { create(:user) }
    let(:admin_role) { create(:admin_role) }
    let(:agent_role) { create(:agent_role) }

    before do
      user.roles << admin_role
      user.roles << agent_role
    end

    it 'includes roles in JSON representation' do
      json = user.as_json
      
      expect(json['roles']).to be_present
      expect(json['roles'].size).to eq(2)
      
      role_data = json['roles'].map { |r| r.slice('id', 'name') }
      expect(role_data).to contain_exactly(
        { 'id' => admin_role.id, 'name' => admin_role.name },
        { 'id' => agent_role.id, 'name' => agent_role.name }
      )
    end

    it 'only includes id and name for roles' do
      json = user.as_json
      
      json['roles'].each do |role_json|
        expect(role_json.keys).to contain_exactly('id', 'name')
      end
    end
  end
end
