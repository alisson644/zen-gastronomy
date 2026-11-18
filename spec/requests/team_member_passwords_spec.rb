require "rails_helper"

RSpec.describe "Team member passwords", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:owner) { create(:user) }
  let(:company) { owner.company }
  let(:member) { create(:user, :administrativo, company: company, email: "ana@example.com") }

  def change_password(user, password: "novaSenha123", confirmation: password)
    patch team_member_password_path(user), params: { user: { password: password, password_confirmation: confirmation } }
  end

  def can_log_in?(email, password)
    post user_session_path, params: { user: { email: email, password: password } }
    ok = response.redirect? && response.location !~ /sign_in/
    delete destroy_user_session_path
    ok
  end

  context "as dono" do
    before { sign_in owner }

    it "shows a change-password action for other members, not for itself" do
      member
      get team_members_path
      expect(response.body).to include(edit_team_member_password_path(member))
      expect(response.body).not_to include(edit_team_member_password_path(owner))
    end

    it "shows the form" do
      get edit_team_member_password_path(member)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nova senha", member.username, member.email)
    end

    it "changes the member's password" do
      change_password(member)

      expect(response).to redirect_to(team_members_path)
      follow_redirect!
      expect(response.body).to include("Senha de #{member.username} alterada")

      sign_out owner
      expect(can_log_in?("ana@example.com", "novaSenha123")).to be true
      expect(can_log_in?("ana@example.com", "hash_senha")).to be false
    end

    it "rejects a confirmation that does not match" do
      change_password(member, confirmation: "outraCoisa")
      expect(response).to have_http_status(:unprocessable_content)
      expect(member.reload.valid_password?("hash_senha")).to be true
    end

    it "rejects a blank password" do
      change_password(member, password: "")
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Nova senha")
      expect(member.reload.valid_password?("hash_senha")).to be true
    end

    it "rejects a too short password" do
      change_password(member, password: "123")
      expect(response).to have_http_status(:unprocessable_content)
      expect(member.reload.valid_password?("hash_senha")).to be true
    end

    it "does not change the password of another company's user" do
      outsider = create(:user)
      change_password(outsider)
      expect(response).to have_http_status(:not_found)
      expect(outsider.reload.valid_password?("hash_senha")).to be true
    end

    it "sends the owner to the profile page to change its own password" do
      change_password(owner)
      expect(response).to redirect_to(edit_user_registration_path)
      expect(owner.reload.valid_password?("hash_senha")).to be true
    end
  end

  context "as system admin viewing the company" do
    it "changes the member's password" do
      sign_in create(:user, :admin)
      post admin_company_view_path, params: { company_id: company.id }

      change_password(member)
      expect(member.reload.valid_password?("novaSenha123")).to be true
    end
  end

  context "as administrativo" do
    it "is forbidden" do
      sign_in create(:user, :administrativo, company: company)
      change_password(owner)
      expect(response).to have_http_status(:forbidden)
      expect(owner.reload.valid_password?("hash_senha")).to be true
    end
  end
end
