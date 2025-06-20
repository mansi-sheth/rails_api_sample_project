# frozen_string_literal: true

# == Schema Information
#
# Table name: user_roles
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_roles_on_role_id              (role_id)
#  index_user_roles_on_user_id              (user_id)
#  index_user_roles_on_user_id_and_role_id  (user_id,role_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (role_id => roles.id)
#  fk_rails_...  (user_id => users.id)
#

describe UserRole do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:role) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }
    
    before { create(:user_role, user: user, role: role) }

    it 'validates uniqueness of user_id scoped to role_id' do
      duplicate_user_role = build(:user_role, user: user, role: role)
      expect(duplicate_user_role).not_to be_valid
      expect(duplicate_user_role.errors[:user_id]).to include('already has this role')
    end

    it 'allows same user to have different roles' do
      different_role = create(:role, name: 'Different Role')
      user_role = build(:user_role, user: user, role: different_role)
      expect(user_role).to be_valid
    end

    it 'allows same role to be assigned to different users' do
      different_user = create(:user, email: 'different@example.com')
      user_role = build(:user_role, user: different_user, role: role)
      expect(user_role).to be_valid
    end
  end

  describe 'factory' do
    it 'creates a valid user_role when properly associated' do
      user = create(:user)
      role = create(:role)
      user_role = build(:user_role, user: user, role: role)
      expect(user_role).to be_valid
    end
  end

  describe 'database constraints' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }

    it 'enforces unique constraint at database level' do
      UserRole.create!(user: user, role: role)
      expect {
        UserRole.create!(user: user, role: role)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end