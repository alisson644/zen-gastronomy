require "rails_helper"

RSpec.describe "Password reset", type: :request do
  it "does not reveal whether an e-mail is registered" do
    create(:user, email: "existe@restaurante.com")

    post user_password_path, params: { user: { email: "existe@restaurante.com" } }
    known = [ response.status, response.location ]

    post user_password_path, params: { user: { email: "nao-existe@restaurante.com" } }
    expect([ response.status, response.location ]).to eq(known)
  end
end
