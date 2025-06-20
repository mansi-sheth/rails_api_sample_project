# frozen_string_literal: true

describe 'PUT api/v1/user/' do
  subject { put api_v1_user_path, params:, headers: auth_headers, as: :json }

  let(:user)             { create(:user) }
  let(:api_v1_user_path) { '/api/v1/user' }

  before { subject }

  context 'with valid params' do
    let(:params) { { user: { username: 'new username' } } }

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

  context 'with role updates' do
    let(:admin_role) { create(:admin_role) }
    let(:agent_role) { create(:agent_role) }
    let(:requester_role) { create(:requester_role) }

    context 'adding roles to user' do
      let(:params) do
        { user: { role_ids: [admin_role.id, agent_role.id] } }
      end

      before do
        admin_role
        agent_role
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'returns success' do
        expect(response).to have_http_status(:success)
      end

      it 'assigns roles to the user' do
        expect(user.reload.roles).to contain_exactly(admin_role, agent_role)
      end

      it 'includes roles in JSON response' do
        expect(json[:user][:roles]).to be_present
        expect(json[:user][:roles].size).to eq(2)
        
        role_ids = json[:user][:roles].map { |r| r[:id] }
        expect(role_ids).to contain_exactly(admin_role.id, agent_role.id)
      end
    end

    context 'updating existing roles' do
      before do
        user.roles << admin_role
        user.roles << agent_role
      end

      let(:params) do
        { user: { role_ids: [admin_role.id, requester_role.id] } }
      end

      before do
        requester_role
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'updates user roles correctly' do
        expect(user.reload.roles).to contain_exactly(admin_role, requester_role)
      end

      it 'removes roles not in the new list' do
        expect(user.reload.roles).not_to include(agent_role)
      end
    end

    context 'removing all roles' do
      before do
        user.roles << admin_role
        user.roles << agent_role
      end

      let(:params) do
        { user: { role_ids: [] } }
      end

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'removes all roles from user' do
        expect(user.reload.roles).to be_empty
      end

      it 'returns empty roles array in response' do
        expect(json[:user][:roles]).to eq([])
      end
    end

    context 'with string role_ids' do
      let(:params) do
        { user: { role_ids: [admin_role.id.to_s, agent_role.id.to_s] } }
      end

      before do
        admin_role
        agent_role
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'correctly handles string IDs' do
        expect(user.reload.roles).to contain_exactly(admin_role, agent_role)
      end
    end

    context 'with invalid role_ids' do
      let(:params) do
        { user: { role_ids: [999999] } }
      end

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'returns client error for invalid role' do
        expect(response).to be_client_error
      end

      it 'does not modify existing roles' do
        expect(user.reload.roles).to be_empty
      end
    end

    context 'updating roles along with other attributes' do
      let(:params) do
        { 
          user: { 
            username: 'updated username',
            first_name: 'Updated First',
            role_ids: [admin_role.id]
          } 
        }
      end

      before do
        admin_role
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'updates both user attributes and roles' do
        user.reload
        expect(user.username).to eq('updated username')
        expect(user.first_name).to eq('Updated First')
        expect(user.roles).to contain_exactly(admin_role)
      end
    end
  end

  context 'with invalid data' do
    let(:params) { { user: { email: 'notanemail' } } }

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

    it 'returns the missing params error' do
      expect(json.dig(:errors, 0, :message)).to eq 'A required param is missing'
    end
  end
end
