# frozen_string_literal: true

require 'rails_helper'

describe 'GET /api/v1/roles' do
  subject { get '/api/v1/roles', headers: auth_headers }

  let(:user) { create(:user) }
  let!(:admin_role) { create(:admin_role) }
  let!(:custom_role) { create(:role, name: 'Custom Role') }

  it_behaves_like 'there must not be a Set-Cookie in Header'

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Authenticated user listing all roles
  # Impact: Core API functionality
  it 'returns success' do
    subject
    expect(response).to have_http_status(:success)
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Returning all roles data
  # Impact: API data delivery
  it 'returns all roles' do
    subject
    response_body = JSON.parse(response.body)
    
    expect(response_body).to be_an(Array)
    expect(response_body.length).to eq(2)
    
    role_names = response_body.map { |role| role['name'] }
    expect(role_names).to include('Admin', 'Custom Role')
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Returning proper role attributes
  # Impact: API data delivery
  it 'returns roles with correct attributes' do
    subject
    response_body = JSON.parse(response.body)
    
    admin_role_data = response_body.find { |role| role['name'] == 'Admin' }
    expect(admin_role_data).to include(
      'id' => admin_role.id,
      'name' => 'Admin',
      'default' => true
    )
    
    custom_role_data = response_body.find { |role| role['name'] == 'Custom Role' }
    expect(custom_role_data).to include(
      'id' => custom_role.id,
      'name' => 'Custom Role',
      'default' => false
    )
  end

  context 'when user is not authenticated' do
    subject { get '/api/v1/roles' }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Unauthenticated access attempt
    # Impact: API security
    it 'returns unauthorized status' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when only default roles exist' do
    before do
      Role.destroy_all
      Role.create_defaults
    end

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Only default roles in system
    # Impact: API data delivery
    it 'returns default roles' do
      subject
      response_body = JSON.parse(response.body)
      expect(response_body.length).to eq(3)
      default_role_names = response_body.map { |role| role['name'] }
      expect(default_role_names).to match_array(['Admin', 'Agent', 'Requester'])
      expect(response).to have_http_status(:success)
    end
  end
end 