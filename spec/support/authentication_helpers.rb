module AuthenticationHelpers
  def login_user(user, password: "password123")
    post session_path, params: {email_address: user.email_address, password: password}
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
