# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  describe 'associations' do
    it { should have_many(:user_roles).dependent(:destroy) }
    it { should have_many(:users).through(:user_roles) }
  end

  describe 'validations' do
    subject { build(:role) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'scopes' do
    let!(:default_role) { create(:admin_role) }
    let!(:custom_role) { create(:role, name: 'Custom Role', default: false) }

    describe '.default' do
      it 'returns only default roles' do
        expect(Role.default).to contain_exactly(default_role)
      end
    end

    describe '.custom' do
      it 'returns only custom roles' do
        expect(Role.custom).to contain_exactly(custom_role)
      end
    end
  end

  describe 'constants' do
    it 'defines expected default role constants' do
      expect(Role::ADMIN).to eq('Admin')
      expect(Role::AGENT).to eq('Agent')
      expect(Role::REQUESTER).to eq('Requester')
    end
  end

  describe '.default_roles' do
    it 'returns array of default role names' do
      expect(Role.default_roles).to match_array([Role::ADMIN, Role::AGENT, Role::REQUESTER])
    end
  end

  describe '.create_defaults' do
    before { Role.destroy_all }

    it 'creates all default roles' do
      expect { Role.create_defaults }.to change(Role, :count).by(3)
    end

    it 'creates roles with correct names and default flag' do
      Role.create_defaults
      
      admin_role = Role.find_by(name: Role::ADMIN)
      agent_role = Role.find_by(name: Role::AGENT)
      requester_role = Role.find_by(name: Role::REQUESTER)

      expect(admin_role).to be_default
      expect(agent_role).to be_default
      expect(requester_role).to be_default
    end

    it 'does not create duplicate roles if they already exist' do
      Role.create_defaults
      expect { Role.create_defaults }.not_to change(Role, :count)
    end
  end

  describe 'deletion protection' do
    context 'when role is default' do
      let(:default_role) { create(:admin_role) }

      it 'prevents deletion of default role' do
        expect { default_role.destroy }.not_to change(Role, :count)
      end

      it 'adds error when trying to delete default role' do
        default_role.destroy
        expect(default_role.errors[:base]).to include('Cannot delete a default role')
      end
    end

    context 'when role is custom' do
      let(:custom_role) { create(:role, name: 'Custom Role', default: false) }

      it 'allows deletion of custom role' do
        expect { custom_role.destroy }.to change(Role, :count).by(-1)
      end
    end
  end

  describe 'case insensitive uniqueness' do
    let!(:existing_role) { create(:role, name: 'Test Role') }

    it 'prevents creation of role with same name in different case' do
      duplicate_role = build(:role, name: 'TEST ROLE')
      expect(duplicate_role).not_to be_valid
      expect(duplicate_role.errors[:name]).to include('has already been taken')
    end
  end
end