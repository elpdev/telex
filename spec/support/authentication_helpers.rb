module AuthenticationHelpers
  def login_user(user, password: "password123")
    post session_path, params: {email_address: user.email_address, password: password}
  end

  def api_headers_for(user = create(:user), api_key: create(:api_key, user: user))
    token = JWTService.encode(user_id: user.id, api_key_id: api_key.id)
    {
      "Authorization" => "Bearer #{token}",
      "ACCEPT" => "application/json"
    }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
