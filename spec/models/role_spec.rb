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

describe Role do
  describe 'associations' do
    it { is_expected.to have_many(:user_roles).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:user_roles) }
  end

  describe 'validations' do
    subject { build(:role) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'constants' do
    it 'defines default role constants' do
      expect(Role::ADMIN).to eq('Admin')
      expect(Role::AGENT).to eq('Agent')
      expect(Role::REQUESTER).to eq('Requester')
    end
  end

  describe 'scopes' do
    let!(:admin_role) { create(:admin_role) }
    let!(:custom_role) { create(:role, name: 'Custom Role', default: false) }

    describe '.default' do
      it 'returns only default roles' do
        expect(Role.default).to include(admin_role)
        expect(Role.default).not_to include(custom_role)
      end
    end

    describe '.custom' do
      it 'returns only custom roles' do
        expect(Role.custom).to include(custom_role)
        expect(Role.custom).not_to include(admin_role)
      end
    end
  end

  describe '.default_roles' do
    it 'returns array of default role names' do
      expect(Role.default_roles).to eq(['Admin', 'Agent', 'Requester'])
    end
  end

  describe '.create_defaults' do
    before { Role.destroy_all }

    it 'creates all default roles' do
      expect { Role.create_defaults }.to change(Role, :count).by(3)
    end

    it 'creates roles with correct names and default flag' do
      Role.create_defaults
      
      admin = Role.find_by(name: 'Admin')
      agent = Role.find_by(name: 'Agent')
      requester = Role.find_by(name: 'Requester')

      expect(admin).to be_present
      expect(admin).to be_default
      expect(agent).to be_present
      expect(agent).to be_default
      expect(requester).to be_present
      expect(requester).to be_default
    end

    it 'does not create duplicates when called multiple times' do
      Role.create_defaults
      expect { Role.create_defaults }.not_to change(Role, :count)
    end
  end

  describe 'callbacks' do
    describe 'before_destroy' do
      context 'when role is default' do
        let(:admin_role) { create(:admin_role) }

        it 'prevents deletion and adds error' do
          expect { admin_role.destroy }.not_to change(Role, :count)
          expect(admin_role.errors[:base]).to include('Cannot delete a default role')
        end
      end

      context 'when role is custom' do
        let(:custom_role) { create(:role, name: 'Custom Role', default: false) }

        it 'allows deletion' do
          expect { custom_role.destroy }.to change(Role, :count).by(-1)
        end
      end
    end
  end

  describe 'instance methods' do
    describe '#default?' do
      it 'returns true for default roles' do
        admin_role = create(:admin_role)
        expect(admin_role).to be_default
      end

      it 'returns false for custom roles' do
        custom_role = create(:role, default: false)
        expect(custom_role).not_to be_default
      end
    end
  end

  describe 'factory' do
    it 'creates a valid role' do
      role = build(:role)
      expect(role).to be_valid
    end

    it 'creates valid default role factories' do
      admin = build(:admin_role)
      agent = build(:agent_role)
      requester = build(:requester_role)

      expect(admin).to be_valid
      expect(admin.name).to eq('Admin')
      expect(admin).to be_default

      expect(agent).to be_valid
      expect(agent.name).to eq('Agent')
      expect(agent).to be_default

      expect(requester).to be_valid
      expect(requester.name).to eq('Requester')
      expect(requester).to be_default
    end
  end
end