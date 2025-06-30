# frozen_string_literal: true

require 'rails_helper'

describe UserRole do
  describe 'validations' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }
    subject { build(:user_role, user: user, role: role) }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: User can only have unique roles
    # Impact: Data integrity
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:role_id).with_message('already has this role') }
  end

  describe 'associations' do
    # Classification: High Importance
    # Type: Happy Path
    # Scenario: UserRole belongs to user
    # Impact: Data relationships
    it { is_expected.to belong_to(:user) }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: UserRole belongs to role
    # Impact: Data relationships
    it { is_expected.to belong_to(:role) }
  end

  describe 'uniqueness validation' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }
    let!(:existing_user_role) { create(:user_role, user: user, role: role) }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Preventing duplicate user-role assignments
    # Impact: Data integrity
    it 'prevents duplicate user-role associations' do
      duplicate_user_role = build(:user_role, user: user, role: role)
      expect(duplicate_user_role).not_to be_valid
      expect(duplicate_user_role.errors[:user_id]).to include('already has this role')
    end

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Allowing same user with different roles
    # Impact: Core business functionality
    it 'allows same user to have different roles' do
      other_role = create(:role, name: 'Other Role')
      new_user_role = build(:user_role, user: user, role: other_role)
      expect(new_user_role).to be_valid
    end

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Allowing same role for different users
    # Impact: Core business functionality
    it 'allows same role to be assigned to different users' do
      other_user = create(:user)
      new_user_role = build(:user_role, user: other_user, role: role)
      expect(new_user_role).to be_valid
    end
  end

  describe 'factory' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }

    # Classification: Low Importance
    # Type: Happy Path
    # Scenario: UserRole factory creates valid association
    # Impact: Test infrastructure
    it 'creates valid user_role with associations' do
      user_role = build(:user_role, user: user, role: role)
      expect(user_role).to be_valid
      expect(user_role.user).to eq(user)
      expect(user_role.role).to eq(role)
    end
  end

  describe 'database constraints' do
    let(:user) { create(:user) }
    let(:role) { create(:role) }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Database-level uniqueness constraint
    # Impact: Data integrity
    it 'enforces uniqueness at database level' do
      create(:user_role, user: user, role: role)
      
      expect {
        # Bypass ActiveRecord validations to test database constraint
        UserRole.connection.execute(
          "INSERT INTO user_roles (user_id, role_id, created_at, updated_at) VALUES (#{user.id}, #{role.id}, NOW(), NOW())"
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end 