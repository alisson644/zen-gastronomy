require "rails_helper"

RSpec.describe "Avatars", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before { sign_in user }

  describe "PATCH /avatar" do
    it "saves only the photo, without asking for the current password" do
      patch avatar_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png") } }

      expect(response).to redirect_to(edit_user_registration_path)
      expect(user.reload.avatar).to be_attached
      follow_redirect!
      expect(response.body).to include("Foto atualizada")
    end

    it "ignores the other profile fields sent along with the form" do
      patch avatar_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png"), username: "Outro nome", email: "outro@example.com" } }

      user.reload
      expect(user.username).to eq("João Silva")
      expect(user.email).not_to eq("outro@example.com")
    end

    it "rejects an invalid file" do
      patch avatar_path, params: { user: { avatar: fixture_file_upload("avatar.txt", "text/plain") } }

      expect(response).to redirect_to(edit_user_registration_path)
      expect(user.reload.avatar).not_to be_attached
      follow_redirect!
      expect(response.body).to include("deve ser PNG, JPG ou WEBP")
    end

    it "asks to choose a file when none is sent" do
      patch avatar_path, params: { user: { username: "x" } }

      expect(user.reload.avatar).not_to be_attached
      follow_redirect!
      expect(response.body).to include("Selecione uma foto")
    end

    it "requires authentication" do
      sign_out user
      patch avatar_path, params: { user: { avatar: fixture_file_upload("avatar.png", "image/png") } }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "profile page" do
    it "has a save-photo-only button that submits to the avatar endpoint" do
      get edit_user_registration_path
      expect(response.body).to include("Salvar foto")
      expect(response.body).to include(%(formaction="#{avatar_path}"))
    end
  end
end
