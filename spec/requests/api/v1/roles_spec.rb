# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Roles', type: :request do
  let(:user) { create(:user) }
  let(:admin_role) { create(:admin_role) }
  let(:agent_role) { create(:agent_role) }
  let(:custom_role) { create(:role, name: 'Custom Role', default: false) }

  before do
    sign_in user
  end

  describe 'GET /api/v1/roles' do
    before do
      admin_role
      agent_role
      custom_role
    end

    it 'returns all roles' do
      get '/api/v1/roles'
      
      expect(response).to have_http_status(:ok)
      expect(json_response.size).to eq(3)
      
      role_names = json_response.map { |role| role['name'] }
      expect(role_names).to contain_exactly(admin_role.name, agent_role.name, custom_role.name)
    end

    it 'returns roles with correct attributes' do
      get '/api/v1/roles'
      
      role = json_response.find { |r| r['id'] == admin_role.id }
      expect(role).to include(
        'id' => admin_role.id,
        'name' => admin_role.name,
        'default' => admin_role.default,
        'created_at' => admin_role.created_at.as_json,
        'updated_at' => admin_role.updated_at.as_json
      )
    end
  end

  describe 'GET /api/v1/roles/:id' do
    context 'when role exists' do
      it 'returns the role' do
        get "/api/v1/roles/#{admin_role.id}"
        
        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'id' => admin_role.id,
          'name' => admin_role.name,
          'default' => admin_role.default
        )
      end
    end

    context 'when role does not exist' do
      it 'returns not found error' do
        get '/api/v1/roles/999999'
        
        expect(response).to have_http_status(:not_found)
        expect(json_response).to include('error' => 'Role not found')
      end
    end
  end

  describe 'POST /api/v1/roles' do
    let(:valid_attributes) { { role: { name: 'New Custom Role' } } }
    let(:invalid_attributes) { { role: { name: '' } } }

    context 'with valid parameters' do
      it 'creates a new role' do
        expect {
          post '/api/v1/roles', params: valid_attributes
        }.to change(Role, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/roles', params: valid_attributes
        
        expect(response).to have_http_status(:created)
        expect(json_response).to include(
          'name' => 'New Custom Role',
          'default' => false
        )
      end

      it 'creates non-default role by default' do
        post '/api/v1/roles', params: valid_attributes
        
        created_role = Role.find(json_response['id'])
        expect(created_role).not_to be_default
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new role' do
        expect {
          post '/api/v1/roles', params: invalid_attributes
        }.not_to change(Role, :count)
      end

      it 'returns unprocessable entity status' do
        post '/api/v1/roles', params: invalid_attributes
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key('name')
      end
    end

    context 'with duplicate name' do
      before { admin_role }

      it 'returns validation error' do
        post '/api/v1/roles', params: { role: { name: admin_role.name } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['name']).to include('has already been taken')
      end
    end

    context 'with case insensitive duplicate name' do
      before { admin_role }

      it 'returns validation error' do
        post '/api/v1/roles', params: { role: { name: admin_role.name.upcase } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['name']).to include('has already been taken')
      end
    end
  end

  describe 'PATCH/PUT /api/v1/roles/:id' do
    let(:new_attributes) { { role: { name: 'Updated Role Name' } } }

    context 'when updating custom role' do
      context 'with valid parameters' do
        it 'updates the role' do
          patch "/api/v1/roles/#{custom_role.id}", params: new_attributes
          
          custom_role.reload
          expect(custom_role.name).to eq('Updated Role Name')
        end

        it 'returns ok status' do
          patch "/api/v1/roles/#{custom_role.id}", params: new_attributes
          
          expect(response).to have_http_status(:ok)
          expect(json_response['name']).to eq('Updated Role Name')
        end
      end

      context 'with invalid parameters' do
        it 'returns unprocessable entity status' do
          patch "/api/v1/roles/#{custom_role.id}", params: { role: { name: '' } }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response).to have_key('name')
        end
      end
    end

    context 'when updating default role' do
      it 'prevents modification of default role' do
        patch "/api/v1/roles/#{admin_role.id}", params: new_attributes
        
        expect(response).to have_http_status(:forbidden)
        expect(json_response['error']).to eq('Cannot modify a default role')
      end

      it 'does not update the role' do
        original_name = admin_role.name
        patch "/api/v1/roles/#{admin_role.id}", params: new_attributes
        
        admin_role.reload
        expect(admin_role.name).to eq(original_name)
      end
    end

    context 'when role does not exist' do
      it 'returns not found error' do
        patch '/api/v1/roles/999999', params: new_attributes
        
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Role not found')
      end
    end
  end

  describe 'DELETE /api/v1/roles/:id' do
    context 'when deleting custom role' do
      it 'deletes the role' do
        role_id = custom_role.id
        
        expect {
          delete "/api/v1/roles/#{role_id}"
        }.to change(Role, :count).by(-1)
        
        expect(Role.find_by(id: role_id)).to be_nil
      end

      it 'returns no content status' do
        delete "/api/v1/roles/#{custom_role.id}"
        
        expect(response).to have_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when deleting default role' do
      it 'prevents deletion of default role' do
        expect {
          delete "/api/v1/roles/#{admin_role.id}"
        }.not_to change(Role, :count)
      end

      it 'returns unprocessable entity status' do
        delete "/api/v1/roles/#{admin_role.id}"
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Cannot delete a default role')
      end
    end

    context 'when role does not exist' do
      it 'returns not found error' do
        delete '/api/v1/roles/999999'
        
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Role not found')
      end
    end

    context 'when role has associated users' do
      before do
        user.roles << custom_role
      end

      it 'deletes the role and removes user associations' do
        expect {
          delete "/api/v1/roles/#{custom_role.id}"
        }.to change(Role, :count).by(-1)
          .and change(UserRole, :count).by(-1)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end