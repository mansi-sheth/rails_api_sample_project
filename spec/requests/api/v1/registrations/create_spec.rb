# frozen_string_literal: true

describe 'POST api/v1/users/sign_up' do
  subject { post user_registration_path, params:, as: :json }

  let(:params) do
    {
      user: {
        email: 'email@example.com',
        password: 'password',
        password_confirmation: 'password',
        username: 'username',
        first_name: 'first name',
        last_name: 'last name'
      }
    }
  end

  context 'with correct params' do
    before do
      subject
    end

    it_behaves_like 'there must not be a Set-Cookie in Header'
    it_behaves_like 'does not check authenticity token'

    it 'returns success' do
      expect(response).to be_successful
    end

    it 'returns the user' do
      user = User.last
      expect(json[:user][:id]).to eq(user.id)
      expect(json[:user][:email]).to eq(params.dig(:user, :email))
      expect(json[:user][:username]).to eq(params.dig(:user, :username))
      expect(json[:user][:uid]).to eq(user.uid)
      expect(json[:user][:provider]).to eq('email')
      expect(json[:user][:first_name]).to eq(params.dig(:user, :first_name))
      expect(json[:user][:last_name]).to eq(params.dig(:user, :last_name))
    end

    it 'returns a valid client and access token' do
      user = User.last
      token = response.header['access-token']
      client = response.header['client']
      expect(user.reload).to be_valid_token(token, client)
    end
  end

  context 'with incorrect params' do
    let(:params) do
      {
        user: {
          email: 'email@example.com',
          password: 'password',
          password_confirmation: 'wrong_password!'
        }
      }
    end

    it 'returns to be a client error' do
      subject
      expect(response).to be_client_error
    end

    it 'return errors upon failure' do
      subject
      expect(json.to_s).to match("Password confirmation doesn't match Password")
    end
  end

  context 'with role_ids parameter' do
    let(:role1) { create(:role, name: 'Manager') }
    let(:role2) { create(:role, name: 'Developer') }

    context 'when registering user with roles' do
      let(:params) do
        {
          user: {
            email: 'email@example.com',
            password: 'password',
            password_confirmation: 'password',
            username: 'username',
            first_name: 'first name',
            last_name: 'last name',
            role_ids: [role1.id, role2.id]
          }
        }
      end

      before { subject }

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: User registration with role assignment
      # Impact: User registration and role management functionality
      it 'creates user with assigned roles' do
        user = User.last
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

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: User registration successful with roles
      # Impact: User registration functionality
      it 'returns success with role data' do
        expect(response).to be_successful
        user = User.last
        expect(json[:user][:id]).to eq(user.id)
        expect(json[:user][:roles]).to be_an(Array)
      end
    end

    context 'when registering user with string role_ids' do
      let(:params) do
        {
          user: {
            email: 'email@example.com',
            password: 'password',
            password_confirmation: 'password',
            username: 'username',
            role_ids: [role1.id.to_s, role2.id.to_s]
          }
        }
      end

      before { subject }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: String role IDs during registration
      # Impact: User registration functionality
      it 'handles string role_ids correctly' do
        user = User.last
        expect(user.roles).to match_array([role1, role2])
      end
    end

    context 'when registering user with invalid role_ids' do
      let(:params) do
        {
          user: {
            email: 'email@example.com',
            password: 'password',
            password_confirmation: 'password',
            username: 'username',
            role_ids: [99999, role1.id]
          }
        }
      end

      before { subject }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Invalid role IDs during registration
      # Impact: Error handling and user registration
      it 'ignores invalid role_ids and assigns valid ones' do
        user = User.last
        expect(user.roles).to match_array([role1])
      end

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Registration succeeds despite invalid role IDs
      # Impact: User registration functionality
      it 'still creates user successfully' do
        expect(response).to be_successful
        expect(User.last).to be_present
      end
    end

    context 'when registering user with empty role_ids' do
      let(:params) do
        {
          user: {
            email: 'email@example.com',
            password: 'password',
            password_confirmation: 'password',
            username: 'username',
            role_ids: []
          }
        }
      end

      before { subject }

      # Classification: High Importance
      # Type: Edge Case
      # Scenario: Registration with empty roles array
      # Impact: User registration functionality
      it 'creates user with no roles' do
        user = User.last
        expect(user.roles).to be_empty
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Response shows empty roles array
      # Impact: API data delivery
      it 'returns user with empty roles array' do
        expect(json[:user][:roles]).to eq([])
      end
    end

    context 'when registering user without role_ids parameter' do
      let(:params) do
        {
          user: {
            email: 'email@example.com',
            password: 'password',
            password_confirmation: 'password',
            username: 'username'
          }
        }
      end

      before { subject }

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Registration without roles parameter
      # Impact: User registration functionality
      it 'creates user with no roles' do
        user = User.last
        expect(user.roles).to be_empty
      end

      # Classification: High Importance
      # Type: Happy Path
      # Scenario: Response includes empty roles array by default
      # Impact: API data delivery
      it 'returns user with empty roles array' do
        expect(json[:user][:roles]).to eq([])
      end
    end
  end
end
