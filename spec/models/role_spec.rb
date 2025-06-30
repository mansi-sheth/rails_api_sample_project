# frozen_string_literal: true

require 'rails_helper'

describe Role do
  describe 'validations' do
    subject { build(:role) }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Role name presence validation
    # Impact: Data integrity
    it { is_expected.to validate_presence_of(:name) }
    
    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Role name uniqueness validation
    # Impact: Data integrity
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'associations' do
    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Role has many user_roles association
    # Impact: Data relationships
    it { is_expected.to have_many(:user_roles).dependent(:destroy) }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Role has many users through user_roles
    # Impact: Data relationships
    it { is_expected.to have_many(:users).through(:user_roles) }
  end

  describe 'constants' do
    # Classification: Low Importance
    # Type: Happy Path
    # Scenario: Default role constants are defined
    # Impact: System configuration
    it 'defines default role constants' do
      expect(described_class::ADMIN).to eq('Admin')
      expect(described_class::AGENT).to eq('Agent')
      expect(described_class::REQUESTER).to eq('Requester')
    end
  end

  describe 'scopes' do
    let!(:default_role) { create(:admin_role) }
    let!(:custom_role) { create(:role, name: 'Custom Role') }

    describe '.default' do
      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Default scope returns only default roles
      # Impact: Core business functionality
      it 'returns only default roles' do
        expect(described_class.default).to include(default_role)
        expect(described_class.default).not_to include(custom_role)
      end
    end

    describe '.custom' do
      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Custom scope returns only non-default roles
      # Impact: Core business functionality
      it 'returns only custom roles' do
        expect(described_class.custom).to include(custom_role)
        expect(described_class.custom).not_to include(default_role)
      end
    end
  end

  describe '.default_roles' do
    # Classification: Low Importance
    # Type: Happy Path
    # Scenario: Default roles array is returned
    # Impact: System configuration
    it 'returns array of default role names' do
      expect(described_class.default_roles).to eq(['Admin', 'Agent', 'Requester'])
    end
  end

  describe '.create_defaults' do
    before { Role.destroy_all }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Creating default roles when none exist
    # Impact: System initialization
    it 'creates default roles' do
      expect { described_class.create_defaults }.to change(described_class, :count).by(3)
      
      admin = described_class.find_by(name: 'Admin')
      agent = described_class.find_by(name: 'Agent')
      requester = described_class.find_by(name: 'Requester')

      expect(admin).to be_present
      expect(admin.default?).to be true
      expect(agent).to be_present
      expect(agent.default?).to be true
      expect(requester).to be_present
      expect(requester.default?).to be true
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Creating default roles when they already exist
    # Impact: System initialization
    it 'does not create duplicate default roles' do
      described_class.create_defaults
      expect { described_class.create_defaults }.not_to change(described_class, :count)
    end
  end

  describe 'callbacks' do
    describe '#ensure_not_default' do
      context 'when role is default' do
        let(:default_role) { create(:admin_role) }

        # Classification: High Importance
        # Type: Edge Case
        # Scenario: Default role deletion prevention
        # Impact: System data integrity
        it 'prevents deletion of default roles' do
          expect { default_role.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        end

        # Classification: High Importance
        # Type: Edge Case
        # Scenario: Default role deletion adds error
        # Impact: System data integrity
        it 'adds error when trying to delete default role' do
          default_role.destroy
          expect(default_role.errors[:base]).to include('Cannot delete a default role')
        end
      end

      context 'when role is not default' do
        let(:custom_role) { create(:role, name: 'Custom Role', default: false) }

        # Classification: High Importance
        # Type: Happy Path
        # Scenario: Custom role deletion allowed
        # Impact: Core business functionality
        it 'allows deletion of custom roles' do
          expect(custom_role.default?).to be false  # Ensure it's not default
          expect { custom_role.destroy! }.to change(described_class, :count).by(-1)
        end
      end
    end
  end

  describe 'factory' do
    # Classification: Low Importance
    # Type: Happy Path
    # Scenario: Role factory creates valid role
    # Impact: Test infrastructure
    it 'creates valid role' do
      role = build(:role)
      expect(role).to be_valid
    end

    # Classification: Low Importance
    # Type: Happy Path
    # Scenario: Admin role factory creates valid admin role
    # Impact: Test infrastructure
    it 'creates valid admin role' do
      admin_role = build(:admin_role)
      expect(admin_role).to be_valid
      expect(admin_role.name).to eq('Admin')
      expect(admin_role.default?).to be true
    end

    # Classification: Low Importance
    # Type: Happy Path
    # Scenario: Agent role factory creates valid agent role
    # Impact: Test infrastructure
    it 'creates valid agent role' do
      agent_role = build(:agent_role)
      expect(agent_role).to be_valid
      expect(agent_role.name).to eq('Agent')
      expect(agent_role.default?).to be true
    end

    # Classification: Low Importance
    # Type: Happy Path
    # Scenario: Requester role factory creates valid requester role
    # Impact: Test infrastructure
    it 'creates valid requester role' do
      requester_role = build(:requester_role)
      expect(requester_role).to be_valid
      expect(requester_role.name).to eq('Requester')
      expect(requester_role.default?).to be true
    end
  end
end 