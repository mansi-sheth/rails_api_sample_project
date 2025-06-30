# frozen_string_literal: true

require 'rails_helper'

describe 'PUT /api/v1/roles/:id' do
  subject { put "/api/v1/roles/#{role.id}", params: { role: role_params }, headers: auth_headers }

  let(:user) { create(:user) }
  let(:role) { create(:role, name: 'Original Role') }
  let(:role_params) { { name: 'Updated Role' } }

  it_behaves_like 'there must not be a Set-Cookie in Header'

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Authenticated user updating a custom role
  # Impact: Core business functionality
  it 'updates the role successfully' do
    subject
    expect(response).to have_http_status(:success)
    expect(role.reload.name).to eq('Updated Role')
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Returning updated role data
  # Impact: API data delivery
  it 'returns the updated role' do
    subject
    response_body = JSON.parse(response.body)
    
    expect(response_body).to include(
      'id' => role.id,
      'name' => 'Updated Role',
      'default' => false
    )
  end

  context 'when user is not authenticated' do
    subject { put "/api/v1/roles/#{role.id}", params: { role: role_params } }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Unauthenticated role update attempt
    # Impact: API security
    it 'returns unauthorized status' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: No role updated without authentication
    # Impact: API security
    it 'does not update the role' do
      subject
      expect(role.reload.name).to eq('Original Role')
    end
  end

  context 'when role does not exist' do
    subject { put '/api/v1/roles/99999', params: { role: role_params }, headers: auth_headers }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Role not found for update
    # Impact: API error handling
    it 'returns not found status' do
      subject
      expect(response).to have_http_status(:not_found)
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Role not found error message
    # Impact: API error handling
    it 'returns error message' do
      subject
      response_body = JSON.parse(response.body)
      expect(response_body['error']).to eq('Role not found')
    end
  end

  context 'when updating a default role' do
    let(:role) { create(:admin_role) }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Default role modification prevention
    # Impact: System data integrity
    it 'prevents updating default roles' do
      subject
      expect(response).to have_http_status(:forbidden)
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Default role update error message
    # Impact: System data integrity
    it 'returns error message for default role' do
      subject
      response_body = JSON.parse(response.body)
      expect(response_body['error']).to eq('Cannot modify a default role')
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Default role remains unchanged
    # Impact: System data integrity
    it 'does not update the default role' do
      original_name = role.name
      subject
      expect(role.reload.name).to eq(original_name)
    end
  end

  context 'with invalid parameters' do
    context 'when name is blank' do
      let(:role_params) { { name: '' } }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Role update with invalid data
      # Impact: Data validation
      it 'returns validation errors' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Role not updated with invalid data
      # Impact: Data validation
      it 'does not update the role' do
        subject
        expect(role.reload.name).to eq('Original Role')
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Returns validation error message
      # Impact: Data validation
      it 'returns error details' do
        subject
        response_body = JSON.parse(response.body)
        expect(response_body).to have_key('name')
        expect(response_body['name']).to include("can't be blank")
      end
    end

    context 'when name already exists' do
      let!(:existing_role) { create(:role, name: 'Existing Role') }
      let(:role_params) { { name: 'Existing Role' } }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Duplicate role name validation on update
      # Impact: Data integrity
      it 'returns validation errors' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Role not updated with duplicate name
      # Impact: Data integrity
      it 'does not update the role' do
        subject
        expect(role.reload.name).to eq('Original Role')
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Returns uniqueness error message
      # Impact: Data integrity
      it 'returns uniqueness error' do
        subject
        response_body = JSON.parse(response.body)
        expect(response_body).to have_key('name')
        expect(response_body['name']).to include('has already been taken')
      end
    end

    context 'when name is case-insensitive duplicate' do
      let!(:existing_role) { create(:role, name: 'Existing Role') }
      let(:role_params) { { name: 'EXISTING ROLE' } }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Case-insensitive uniqueness validation on update
      # Impact: Data integrity
      it 'returns validation errors' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Role not updated with case-insensitive duplicate
      # Impact: Data integrity
      it 'does not update the role' do
        subject
        expect(role.reload.name).to eq('Original Role')
      end
    end
  end

  context 'when attempting to change default status' do
    let(:role_params) { { name: 'Updated Role', default: true } }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Manual default status change attempt
    # Impact: System security
    it 'ignores default parameter and updates only name' do
      subject
      updated_role = role.reload
      expect(updated_role.name).to eq('Updated Role')
      expect(updated_role.default?).to be false
      expect(response).to have_http_status(:success)
    end
  end

  context 'when updating role with same name (case-sensitive)' do
    let(:role_params) { { name: 'Original Role' } }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Updating role with same name
    # Impact: Core business functionality
    it 'allows updating with same name' do
      subject
      expect(response).to have_http_status(:success)
      expect(role.reload.name).to eq('Original Role')
    end
  end

  context 'with various valid role names' do
    ['New Manager', 'Support-Agent_v2', 'Developer123', 'QA Tester'].each do |new_name|
      context "when updating to name '#{new_name}'" do
        let(:role_params) { { name: new_name } }

        # Classification: High Importance
        # Type: Happy Path
        # Scenario: Updating roles with various valid names
        # Impact: Core business functionality
        it "successfully updates to '#{new_name}'" do
          subject
          expect(response).to have_http_status(:success)
          expect(role.reload.name).to eq(new_name)
        end
      end
    end
  end
end 