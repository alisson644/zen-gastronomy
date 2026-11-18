require "rails_helper"

RSpec.describe "Users::Registrations (avatar)", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before { sign_in user }

  def update_user(extra = {})
    put user_registration_path, params: {
      user: { username: user.username, email: user.email, current_password: "hash_senha" }.merge(extra)
    }
  end

  it "shows the default avatar in the sidebar when the user has no photo" do
    get edit_user_registration_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("avatar-default")
  end

  it "uploads a photo and shows it in the sidebar" do
    update_user(avatar: fixture_file_upload("avatar.png", "image/png"))

    expect(user.reload.avatar).to be_attached
    get edit_user_registration_path
    expect(response.body).to include("/rails/active_storage/")
  end

  it "does not attach an invalid file" do
    update_user(avatar: fixture_file_upload("avatar.txt", "text/plain"))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("deve ser PNG, JPG ou WEBP")
    expect(user.reload.avatar).not_to be_attached
  end

  it "removes the photo" do
    user.avatar.attach(fixture_file_upload("avatar.png", "image/png"))

    update_user(remove_avatar: "1")

    expect(user.reload.avatar).not_to be_attached
  end

  it "keeps the new photo when remove is checked together with an upload" do
    user.avatar.attach(fixture_file_upload("avatar.png", "image/png"))
    old_blob_id = user.avatar.blob.id

    update_user(remove_avatar: "1", avatar: fixture_file_upload("avatar.png", "image/png"))

    expect(user.reload.avatar).to be_attached
    expect(user.avatar.blob.id).not_to eq(old_blob_id)
  end
end
