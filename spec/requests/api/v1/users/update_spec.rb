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

  context 'with role_ids parameter' do
    let(:admin_role) { create(:admin_role) }
    let(:agent_role) { create(:agent_role) }
    let(:requester_role) { create(:requester_role) }

    before do
      admin_role
      agent_role
      requester_role
      # Reset the subject call since we need different setup
      response # Force the previous call to complete
    end

    context 'when assigning new roles' do
      let(:params) { { user: { role_ids: [admin_role.id, agent_role.id] } } }

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'returns success' do
        expect(response).to have_http_status(:success)
      end

      it 'assigns roles to the user' do
        expect(user.reload.roles).to include(admin_role, agent_role)
        expect(user.roles.count).to eq(2)
      end

      it 'returns user with roles in response' do
        expect(json[:user][:roles]).to be_present
        expect(json[:user][:roles].length).to eq(2)
        
        role_ids = json[:user][:roles].map { |role| role['id'] }
        expect(role_ids).to include(admin_role.id, agent_role.id)
      end
    end

    context 'when updating existing roles' do
      before do
        user.roles = [admin_role, agent_role]
        user.save
      end

      let(:params) { { user: { role_ids: [requester_role.id] } } }

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'replaces existing roles' do
        expect(user.reload.roles).to include(requester_role)
        expect(user.roles).not_to include(admin_role, agent_role)
        expect(user.roles.count).to eq(1)
      end

      it 'returns updated roles in response' do
        role_ids = json[:user][:roles].map { |role| role['id'] }
        expect(role_ids).to eq([requester_role.id])
      end
    end

    context 'when removing all roles' do
      before do
        user.roles = [admin_role]
        user.save
      end

      let(:params) { { user: { role_ids: [] } } }

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'removes all roles' do
        expect(user.reload.roles).to be_empty
      end

      it 'returns empty roles array' do
        expect(json[:user][:roles]).to eq([])
      end
    end

    context 'when combining role_ids with other params' do
      let(:params) do
        {
          user: {
            username: 'updated_username',
            first_name: 'Updated',
            role_ids: [admin_role.id]
          }
        }
      end

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'updates both user attributes and roles' do
        user.reload
        expect(user.username).to eq('updated_username')
        expect(user.first_name).to eq('Updated')
        expect(user.roles).to include(admin_role)
      end
    end

    context 'with string role_ids' do
      let(:params) { { user: { role_ids: [admin_role.id.to_s, agent_role.id.to_s] } } }

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'handles string role_ids correctly' do
        expect(user.reload.roles).to include(admin_role, agent_role)
      end
    end

    context 'with invalid role_ids' do
      let(:params) { { user: { role_ids: [999999, admin_role.id] } } }

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'ignores invalid role_ids and assigns valid ones' do
        expect(user.reload.roles).to include(admin_role)
        expect(user.roles.count).to eq(1)
      end
    end

    context 'when role_ids is not provided' do
      before do
        user.roles = [admin_role]
        user.save
      end

      let(:params) { { user: { username: 'new_username' } } }

      before do
        put api_v1_user_path, params: params, headers: auth_headers, as: :json
      end

      it 'does not affect existing roles' do
        expect(user.reload.roles).to include(admin_role)
        expect(user.username).to eq('new_username')
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
