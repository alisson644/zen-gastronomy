require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  let!(:user) { create(:user, email: "dono@restaurante.com") }

  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.reset!
    Rack::Attack.enabled = false
  end

  def login(email: user.email, ip: "10.0.0.1")
    post user_session_path, params: { user: { email: email, password: "errada" } }, env: { "REMOTE_ADDR" => ip }
  end

  it "throttles repeated logins from the same IP" do
    5.times { login(email: "x#{rand(10_000)}@ex.com") }
    expect(response).not_to have_http_status(:too_many_requests)

    login(email: "outro@ex.com")
    expect(response).to have_http_status(:too_many_requests)
    expect(response.body).to include("Muitas tentativas")
    expect(response.headers["Retry-After"].to_i).to be_positive
  end

  it "throttles logins to the same e-mail from different IPs" do
    5.times { |i| login(email: " DONO@restaurante.com ", ip: "10.0.1.#{i}") }
    login(ip: "10.0.2.1")
    expect(response).to have_http_status(:too_many_requests)
  end

  it "throttles password reset requests for the same e-mail" do
    3.times { |i| post user_password_path, params: { user: { email: user.email } }, env: { "REMOTE_ADDR" => "10.0.3.#{i}" } }
    post user_password_path, params: { user: { email: user.email } }, env: { "REMOTE_ADDR" => "10.0.4.1" }
    expect(response).to have_http_status(:too_many_requests)
  end

  it "throttles sign-ups from the same IP" do
    10.times { post user_registration_path, params: { user: { email: "" } }, env: { "REMOTE_ADDR" => "10.0.5.1" } }
    post user_registration_path, params: { user: { email: "" } }, env: { "REMOTE_ADDR" => "10.0.5.1" }
    expect(response).to have_http_status(:too_many_requests)
  end

  it "never limits the health check" do
    310.times { get rails_health_check_path, env: { "REMOTE_ADDR" => "10.0.6.1" } }
    expect(response).to have_http_status(:ok)
  end

  it "bans an IP probing for scanner paths" do
    get "/wp-login.php", env: { "REMOTE_ADDR" => "10.0.7.1" }
    expect(response).to have_http_status(:forbidden)
    2.times { get "/.env", env: { "REMOTE_ADDR" => "10.0.7.1" } }

    get root_path, env: { "REMOTE_ADDR" => "10.0.7.1" }
    expect(response).to have_http_status(:forbidden)

    get root_path, env: { "REMOTE_ADDR" => "10.0.7.2" }
    expect(response).to have_http_status(:ok)
  end
end
