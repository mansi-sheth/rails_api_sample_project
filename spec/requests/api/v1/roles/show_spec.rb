# frozen_string_literal: true

require 'rails_helper'

describe 'GET /api/v1/roles/:id' do
  subject { get "/api/v1/roles/#{role.id}", headers: auth_headers }

  let(:user) { create(:user) }
  let(:role) { create(:admin_role) }

  it_behaves_like 'there must not be a Set-Cookie in Header'

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Authenticated user viewing a role
  # Impact: Core API functionality
  it 'returns success' do
    subject
    expect(response).to have_http_status(:success)
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Returning specific role data
  # Impact: API data delivery
  it 'returns the requested role' do
    subject
    response_body = JSON.parse(response.body)
    
    expect(response_body).to include(
      'id' => role.id,
      'name' => role.name,
      'default' => role.default?
    )
  end

  # Classification: High Importance
  # Type: Happy Path
  # Scenario: Returning role with all attributes
  # Impact: API data delivery
  it 'includes timestamps in response' do
    subject
    response_body = JSON.parse(response.body)
    
    expect(response_body).to have_key('created_at')
    expect(response_body).to have_key('updated_at')
  end

  context 'when user is not authenticated' do
    subject { get "/api/v1/roles/#{role.id}" }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Unauthenticated access attempt
    # Impact: API security
    it 'returns unauthorized status' do
      subject
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when role does not exist' do
    subject { get '/api/v1/roles/99999', headers: auth_headers }

    # Classification: High Importance
    # Type: Edge Case
    # Scenario: Role not found
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

  context 'with different role types' do
    context 'when viewing default role' do
      let(:role) { create(:admin_role) }

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Viewing default role details
      # Impact: Core API functionality
      it 'returns default role with correct attributes' do
        subject
        response_body = JSON.parse(response.body)
        
        expect(response_body['default']).to be true
        expect(response_body['name']).to eq('Admin')
      end
    end

    context 'when viewing custom role' do
      let(:role) { create(:role, name: 'Custom Role', default: false) }

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Viewing custom role details
      # Impact: Core API functionality
      it 'returns custom role with correct attributes' do
        subject
        response_body = JSON.parse(response.body)
        
        expect(response_body['default']).to be false
        expect(response_body['name']).to eq('Custom Role')
      end
    end
  end
end 