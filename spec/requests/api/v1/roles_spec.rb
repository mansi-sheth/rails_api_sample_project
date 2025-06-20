# frozen_string_literal: true

describe 'API V1 Roles' do
  let(:admin_role) { create(:admin_role) }
  let(:custom_role) { create(:role, name: 'Custom Role', default: false) }

  describe 'GET /api/v1/roles' do
    subject { get '/api/v1/roles', as: :json }

    before do
      admin_role
      custom_role
    end

    it 'returns success' do
      subject
      expect(response).to be_successful
    end

    it 'returns all roles' do
      subject
      expect(json.length).to eq(2)
      
      role_names = json.map { |role| role['name'] }
      expect(role_names).to include('Admin', 'Custom Role')
    end

    it 'returns roles with correct attributes' do
      subject
      
      admin_data = json.find { |role| role['name'] == 'Admin' }
      expect(admin_data['id']).to eq(admin_role.id)
      expect(admin_data['name']).to eq('Admin')
      expect(admin_data['default']).to be(true)
    end
  end

  describe 'GET /api/v1/roles/:id' do
    subject { get "/api/v1/roles/#{role_id}", as: :json }

    context 'when role exists' do
      let(:role_id) { admin_role.id }

      it 'returns success' do
        subject
        expect(response).to be_successful
      end

      it 'returns the role' do
        subject
        expect(json['id']).to eq(admin_role.id)
        expect(json['name']).to eq('Admin')
        expect(json['default']).to be(true)
      end
    end

    context 'when role does not exist' do
      let(:role_id) { 999999 }

      it 'returns not found' do
        subject
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error message' do
        subject
        expect(json['error']).to eq('Role not found')
      end
    end
  end

  describe 'POST /api/v1/roles' do
    subject { post '/api/v1/roles', params: params, as: :json }

    context 'with valid params' do
      let(:params) do
        {
          role: {
            name: 'New Role'
          }
        }
      end

      it 'returns created status' do
        subject
        expect(response).to have_http_status(:created)
      end

      it 'creates a new role' do
        expect { subject }.to change(Role, :count).by(1)
      end

      it 'returns the created role' do
        subject
        expect(json['name']).to eq('New Role')
        expect(json['default']).to be(false)
      end

      it 'creates role with correct attributes' do
        subject
        role = Role.last
        expect(role.name).to eq('New Role')
        expect(role.default).to be(false)
      end
    end

    context 'with invalid params' do
      let(:params) do
        {
          role: {
            name: ''
          }
        }
      end

      it 'returns unprocessable entity' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create a role' do
        expect { subject }.not_to change(Role, :count)
      end

      it 'returns validation errors' do
        subject
        expect(json['name']).to include("can't be blank")
      end
    end

    context 'with duplicate name' do
      let(:params) do
        {
          role: {
            name: admin_role.name
          }
        }
      end

      before { admin_role }

      it 'returns unprocessable entity' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        subject
        expect(json['name']).to include('has already been taken')
      end
    end
  end

  describe 'PATCH /api/v1/roles/:id' do
    subject { patch "/api/v1/roles/#{role_id}", params: params, as: :json }

    context 'when updating a custom role' do
      let(:role_id) { custom_role.id }
      let(:params) do
        {
          role: {
            name: 'Updated Role Name'
          }
        }
      end

      it 'returns success' do
        subject
        expect(response).to be_successful
      end

      it 'updates the role' do
        subject
        expect(custom_role.reload.name).to eq('Updated Role Name')
      end

      it 'returns the updated role' do
        subject
        expect(json['name']).to eq('Updated Role Name')
      end
    end

    context 'when updating a default role' do
      let(:role_id) { admin_role.id }
      let(:params) do
        {
          role: {
            name: 'Updated Admin'
          }
        }
      end

      it 'returns forbidden status' do
        subject
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not update the role' do
        subject
        expect(admin_role.reload.name).to eq('Admin')
      end

      it 'returns error message' do
        subject
        expect(json['error']).to eq('Cannot modify a default role')
      end
    end

    context 'with invalid params' do
      let(:role_id) { custom_role.id }
      let(:params) do
        {
          role: {
            name: ''
          }
        }
      end

      it 'returns unprocessable entity' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        subject
        expect(json['name']).to include("can't be blank")
      end
    end

    context 'when role does not exist' do
      let(:role_id) { 999999 }
      let(:params) do
        {
          role: {
            name: 'Updated Name'
          }
        }
      end

      it 'returns not found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/roles/:id' do
    subject { delete "/api/v1/roles/#{role_id}", as: :json }

    context 'when deleting a custom role' do
      let(:role_id) { custom_role.id }

      before { custom_role }

      it 'returns no content' do
        subject
        expect(response).to have_http_status(:no_content)
      end

      it 'deletes the role' do
        expect { subject }.to change(Role, :count).by(-1)
      end

      it 'removes the role from database' do
        subject
        expect(Role.find_by(id: role_id)).to be_nil
      end
    end

    context 'when deleting a default role' do
      let(:role_id) { admin_role.id }

      before { admin_role }

      it 'returns unprocessable entity' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not delete the role' do
        expect { subject }.not_to change(Role, :count)
      end

      it 'returns error message' do
        subject
        expect(json['error']).to eq('Cannot delete a default role')
      end
    end

    context 'when role has associated users' do
      let(:role_id) { custom_role.id }
      let(:user) { create(:user) }

      before do
        custom_role
        user.roles << custom_role
      end

      it 'returns unprocessable entity' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not delete the role' do
        expect { subject }.not_to change(Role, :count)
      end

      it 'returns error message' do
        subject
        expect(json['error']).to be_present
      end
    end

    context 'when role does not exist' do
      let(:role_id) { 999999 }

      it 'returns not found' do
        subject
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'parameter handling' do
    describe 'missing role parameter' do
      subject { post '/api/v1/roles', params: { name: 'Test' }, as: :json }

      it 'raises parameter missing error' do
        expect { subject }.to raise_error(ActionController::ParameterMissing)
      end
    end

    describe 'unpermitted parameters' do
      subject do
        post '/api/v1/roles', params: {
          role: {
            name: 'Test Role',
            default: true,  # This should be filtered out
            id: 123        # This should be filtered out
          }
        }, as: :json
      end

      it 'filters out unpermitted parameters' do
        subject
        role = Role.last
        expect(role.name).to eq('Test Role')
        expect(role.default).to be(false)  # Should not be set to true
      end
    end
  end
end