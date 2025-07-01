# frozen_string_literal: true

describe 'PUT api/v1/user/' do
  subject { put api_v1_user_path, params:, headers: auth_headers, as: :json }

  let(:user)             { create(:user) }
  let(:api_v1_user_path) { '/api/v1/user' }

  context 'with valid params' do
    let(:params) { { user: { username: 'new username' } } }

    before { subject }

    it 'returns success' do
      expect(response).to have_http_status(:success)
    end

    it 'updates the user' do
      expect(user.reload.username).to eq(params[:user][:username])
    end

    it 'returns the user id' do
      expect(json[:user][:id]).to eq user.id
    end

    it 'returns the user full name' do
      expect(json[:user][:name]).to eq user.reload.full_name
    end
  end

  context 'with invalid data' do
    let(:params) { { user: { email: 'notanemail' } } }

    before { subject }

    it 'does not return success' do
      expect(response).not_to have_http_status(:success)
    end

    it 'does not update the user' do
      expect(user.reload.email).not_to eq(params[:email])
    end

    it 'returns the error' do
      expect(json.dig(:errors, 0, :email)).to include('is not an email')
    end
  end

  context 'with missing params' do
    let(:params) { {} }

    before { subject }

    it 'returns the missing params error' do
      expect(json.dig(:errors, 0, :message)).to eq 'A required param is missing'
    end
  end

  context 'with role_ids parameter' do
    let(:role1) { create(:role, name: 'Manager') }
    let(:role2) { create(:role, name: 'Developer') }
    let(:role3) { create(:role, name: 'Admin') }

    context 'when adding roles to user' do
      let(:params) { { user: { username: 'updated_user', role_ids: [role1.id, role2.id] } } }

      before { subject }

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: User update with role assignment
      # Impact: User role management functionality
      it 'assigns roles to user' do
        expect(user.reload.roles).to match_array([role1, role2])
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: User data and roles updated successfully
      # Impact: User role management functionality
      it 'updates both username and roles' do
        expect(user.reload.username).to eq('updated_user')
        expect(user.roles).to match_array([role1, role2])
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Response includes user with roles
      # Impact: API data delivery
      it 'returns user with roles in response' do
        expect(json[:user][:roles]).to be_present
        expect(json[:user][:roles].length).to eq(2)
        role_names = json[:user][:roles].map { |r| r['name'] }
        expect(role_names).to match_array(['Manager', 'Developer'])
      end
    end

    context 'when updating existing user roles' do
      before do
        user.role_ids = [role1.id, role3.id]
        user.save!
        subject
      end

      let(:params) { { user: { role_ids: [role2.id] } } }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Replacing existing user roles
      # Impact: User role management functionality
      it 'replaces existing roles with new ones' do
        expect(user.reload.roles).to match_array([role2])
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Old roles are removed
      # Impact: User role management functionality
      it 'removes old roles' do
        reloaded_user = user.reload
        expect(reloaded_user.roles).not_to include(role1, role3)
        expect(reloaded_user.roles).to include(role2)
      end
    end

    context 'when removing all roles' do
      before do
        user.role_ids = [role1.id, role2.id]
        user.save!
        subject
      end

      let(:params) { { user: { role_ids: [] } } }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Removing all user roles
      # Impact: User role management functionality
      it 'removes all roles from user' do
        expect(user.reload.roles).to be_empty
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Response shows no roles
      # Impact: API data delivery
      it 'returns user with empty roles array' do
        expect(json[:user][:roles]).to eq([])
      end
    end

    context 'with string role_ids' do
      let(:params) { { user: { role_ids: [role1.id.to_s, role2.id.to_s] } } }

      before { subject }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: String role IDs are handled correctly
      # Impact: User role management functionality
      it 'handles string role_ids correctly' do
        expect(user.reload.roles).to match_array([role1, role2])
      end
    end

    context 'with invalid role_ids' do
      let(:params) { { user: { role_ids: [99999, role1.id] } } }

      before { subject }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Invalid role IDs in request
      # Impact: Error handling
      it 'ignores invalid role_ids and assigns valid ones' do
        expect(user.reload.roles).to match_array([role1])
      end
    end

    context 'without role_ids parameter' do
      before do
        user.role_ids = [role1.id]
        user.save!
        subject
      end

      let(:params) { { user: { username: 'updated_without_roles' } } }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Update without touching roles
      # Impact: User role management functionality
      it 'does not modify existing roles' do
        expect(user.reload.roles).to match_array([role1])
        expect(user.username).to eq('updated_without_roles')
      end
    end
  end
end
