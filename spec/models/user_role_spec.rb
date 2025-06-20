# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:role) }
  end

  describe 'validations' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }

    subject { build(:user_role, user: user, role: role) }

    it { should validate_uniqueness_of(:user_id).scoped_to(:role_id).with_message('already has this role') }
  end

  describe 'uniqueness constraint' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }
    let!(:existing_user_role) { create(:user_role, user: user, role: role) }

    context 'when trying to create duplicate user-role association' do
      it 'prevents duplicate user_role creation' do
        duplicate_user_role = build(:user_role, user: user, role: role)
        expect(duplicate_user_role).not_to be_valid
        expect(duplicate_user_role.errors[:user_id]).to include('already has this role')
      end
    end

    context 'when user has different role' do
      let(:different_role) { create(:role, name: 'Different Role') }

      it 'allows user to have multiple different roles' do
        new_user_role = build(:user_role, user: user, role: different_role)
        expect(new_user_role).to be_valid
      end
    end

    context 'when different user has same role' do
      let(:different_user) { create(:user, email: 'different@example.com') }

      it 'allows different users to have same role' do
        new_user_role = build(:user_role, user: different_user, role: role)
        expect(new_user_role).to be_valid
      end
    end
  end

  describe 'cascade deletion' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }
    let!(:user_role) { create(:user_role, user: user, role: role) }

    context 'when user is deleted' do
      it 'deletes associated user_roles' do
        expect { user.destroy }.to change(UserRole, :count).by(-1)
      end
    end

    context 'when role is deleted' do
      it 'deletes associated user_roles' do
        expect { role.destroy }.to change(UserRole, :count).by(-1)
      end
    end
  end
end