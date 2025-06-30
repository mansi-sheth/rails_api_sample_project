# frozen_string_literal: true

require 'rails_helper'

describe 'DELETE /api/v1/roles/:id' do
  subject { delete "/api/v1/roles/#{role.id}", headers: auth_headers }

  let(:user) { create(:user) }
  let(:role) { create(:role, name: 'Custom Role') }

  it_behaves_like 'there must not be a Set-Cookie in Header'

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Authenticated user deleting a custom role
  # Impact: Core business functionality
  it 'deletes the role successfully' do
    role_id = role.id
    expect { subject }.to change(Role, :count).by(-1)
    expect(response).to have_http_status(:no_content)
    expect(Role.find_by(id: role_id)).to be_nil
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Successful deletion returns no content
  # Impact: API response handling
  it 'returns no content status' do
    subject
    expect(response).to have_http_status(:no_content)
    expect(response.body).to be_empty
  end

  context 'when user is not authenticated' do
    subject { delete "/api/v1/roles/#{role.id}" }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Unauthenticated role deletion attempt
    # Impact: API security
    it 'returns unauthorized status' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: No role deleted without authentication
    # Impact: API security
    it 'does not delete the role' do
      role_id = role.id
      expect { subject }.not_to change(Role, :count)
      expect(Role.find_by(id: role_id)).to be_present
    end
  end

  context 'when role does not exist' do
    subject { delete '/api/v1/roles/99999', headers: auth_headers }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Role not found for deletion
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

  context 'when attempting to delete a default role' do
    let(:role) { create(:admin_role) }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Default role deletion prevention
    # Impact: System data integrity
    it 'prevents deletion of default role' do
      role_id = role.id
      expect { subject }.not_to change(Role, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Role.find_by(id: role_id)).to be_present
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Default role deletion error message
    # Impact: System data integrity
    it 'returns error message for default role deletion' do
      subject
      response_body = JSON.parse(response.body)
      expect(response_body['error']).to eq('Cannot delete a default role')
    end

    context 'with different default roles' do
      ['admin_role', 'agent_role', 'requester_role'].each do |role_factory|
        context "when attempting to delete #{role_factory}" do
          let(:role) { create(role_factory.to_sym) }

          # Classification: High Importance
          # Type: Edge Case
          # Scenario: Various default role deletion prevention
          # Impact: System data integrity
          it "prevents deletion of #{role_factory}" do
            role_id = role.id
            expect { subject }.not_to change(Role, :count)
            expect(response).to have_http_status(:unprocessable_entity)
            expect(Role.find_by(id: role_id)).to be_present
          end
        end
      end
    end
  end

  context 'when role has associated user_roles' do
    let!(:user_role) { create(:user_role, role: role, user: create(:user)) }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Role deletion with associated user_roles
    # Impact: Data consistency and cascade deletion
    it 'deletes the role and associated user_roles' do
      role_id = role.id
      user_role_id = user_role.id
      
      expect { subject }.to change(Role, :count).by(-1)
        .and change(UserRole, :count).by(-1)
      
      expect(response).to have_http_status(:no_content)
      expect(Role.find_by(id: role_id)).to be_nil
      expect(UserRole.find_by(id: user_role_id)).to be_nil
    end

    context 'with multiple user_roles' do
      let!(:additional_user_role) { create(:user_role, role: role, user: create(:user)) }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Role deletion with multiple associated user_roles
      # Impact: Data consistency and cascade deletion
      it 'deletes all associated user_roles' do
        role_id = role.id
        
        expect { subject }.to change(Role, :count).by(-1)
          .and change(UserRole, :count).by(-2)
        
        expect(response).to have_http_status(:no_content)
        expect(Role.find_by(id: role_id)).to be_nil
        expect(UserRole.where(role_id: role_id)).to be_empty
      end
    end
  end

  context 'when attempting to delete default role via callback validation' do
    let(:role) { create(:admin_role) }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Callback-based default role protection
    # Impact: System data integrity
    it 'is protected by model callback' do
      # Test that the model callback works even if controller protection fails
      expect { role.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Callback adds appropriate error
    # Impact: System data integrity
    it 'adds error message via callback' do
      role.destroy
      expect(role.errors[:base]).to include('Cannot delete a default role')
    end
  end

  context 'when database constraints might fail' do
    let(:role) { create(:role, name: 'Test Role') }

    before do
      # Stub destroy to simulate database failure
      allow_any_instance_of(Role).to receive(:destroy).and_return(false)
      allow_any_instance_of(Role).to receive(:errors).and_return(
        double(full_messages: ['Database constraint violation'])
      )
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Database failure during deletion
    # Impact: Error handling and user feedback
    it 'handles database errors gracefully' do
      subject
      expect(response).to have_http_status(:unprocessable_entity)
      
      response_body = JSON.parse(response.body)
      expect(response_body['error']).to eq('Database constraint violation')
    end
  end

  context 'when error messages are empty' do
    let(:role) { create(:role, name: 'Test Role') }

    before do
      # Stub destroy to simulate failure with no specific error messages
      allow_any_instance_of(Role).to receive(:destroy).and_return(false)
      allow_any_instance_of(Role).to receive(:errors).and_return(
        double(full_messages: [])
      )
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Generic error handling when no specific message
    # Impact: Error handling and user feedback
    it 'returns generic error message' do
      subject
      expect(response).to have_http_status(:unprocessable_entity)
      
      response_body = JSON.parse(response.body)
      expect(response_body['error']).to eq('Unable to delete role')
    end
  end

  context 'with multiple custom roles' do
    let!(:role1) { create(:role, name: 'Role 1') }
    let!(:role2) { create(:role, name: 'Role 2') }
    let!(:role3) { create(:role, name: 'Role 3') }

    # Classification: High Importance
    # Type: Happy Path
    # Scenario: Deleting one of multiple custom roles
    # Impact: Core business functionality
    it 'deletes only the specified role' do
      delete "/api/v1/roles/#{role2.id}", headers: auth_headers
      
      expect(response).to have_http_status(:no_content)
      expect(Role.find_by(id: role2.id)).to be_nil
      expect(Role.find_by(id: role1.id)).to be_present
      expect(Role.find_by(id: role3.id)).to be_present
    end
  end
end 