# frozen_string_literal: true

require 'rails_helper'

describe 'POST /api/v1/roles' do
  subject { post '/api/v1/roles', params: { role: role_params }, headers: auth_headers }

  let(:user) { create(:user) }
  let(:role_params) { { name: 'New Role' } }

  it_behaves_like 'there must not be a Set-Cookie in Header'

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Authenticated user creating a new role
  # Impact: Core business functionality
  it 'creates a new role' do
    expect { subject }.to change(Role, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Returning created role data
  # Impact: API data delivery
  it 'returns the created role' do
    subject
    response_body = JSON.parse(response.body)
    
    expect(response_body).to include(
      'name' => 'New Role',
      'default' => false
    )
    expect(response_body).to have_key('id')
    expect(response_body).to have_key('created_at')
    expect(response_body).to have_key('updated_at')
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Creating role with correct attributes
  # Impact: Core business functionality
  it 'creates role with correct attributes' do
    subject
    created_role = Role.last
    
    expect(created_role.name).to eq('New Role')
    expect(created_role.default?).to be false
  end

  context 'when user is not authenticated' do
    subject { post '/api/v1/roles', params: { role: role_params } }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Unauthenticated role creation attempt
    # Impact: API security
    it 'returns unauthorized status' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: No role created without authentication
    # Impact: API security
    it 'does not create a role' do
      expect { subject }.not_to change(Role, :count)
    end
  end

  context 'with invalid parameters' do
    context 'when name is missing' do
      let(:role_params) { { name: '' } }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Role creation with invalid data
      # Impact: Data validation
      it 'returns validation errors' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: No role created with invalid data
      # Impact: Data validation
      it 'does not create a role' do
        expect { subject }.not_to change(Role, :count)
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
      # Scenario: Duplicate role name validation
      # Impact: Data integrity
      it 'returns validation errors' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: No duplicate role created
      # Impact: Data integrity
      it 'does not create a duplicate role' do
        expect { subject }.not_to change(Role, :count)
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
      # Scenario: Case-insensitive uniqueness validation
      # Impact: Data integrity
      it 'returns validation errors' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: No case-insensitive duplicate created
      # Impact: Data integrity
      it 'does not create a case-insensitive duplicate' do
        expect { subject }.not_to change(Role, :count)
      end
    end
  end

  context 'when attempting to create default role manually' do
    let(:role_params) { { name: 'Custom Role', default: true } }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Manual default role creation attempt
    # Impact: System security
    it 'ignores default parameter and creates non-default role' do
      subject
      created_role = Role.last
      expect(created_role.default?).to be false
      expect(response).to have_http_status(:created)
    end
  end

  context 'with various role names' do
    ['Developer', 'Manager', 'Support Agent', 'Custom-Role_123'].each do |role_name|
      context "when creating role with name '#{role_name}'" do
        let(:role_params) { { name: role_name } }

        # Classification: High Importance
        # Type: Happy Path
        # Scenario: Creating roles with various valid names
        # Impact: Core business functionality
        it "successfully creates role '#{role_name}'" do
          expect { subject }.to change(Role, :count).by(1)
          expect(response).to have_http_status(:created)
          expect(Role.last.name).to eq(role_name)
        end
      end
    end
  end
end 