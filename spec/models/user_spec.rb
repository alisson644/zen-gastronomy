require 'rails_helper'

RSpec.describe User, type: :model do
  it { should belong_to(:company).optional(true) }
  it { should have_many(:movements).dependent(:destroy) }

  it { should validate_presence_of(:username) }
  it { should validate_presence_of(:email) }

  it "with unic email valid in company" do
    company = FactoryBot.create(:company)
    FactoryBot.create(:user, company_id: company.id, email: "test@example.com")
    user = FactoryBot.build(:user, company_id: company.id, email: "test@example.com")
    expect(user).not_to be_valid
  end

  describe "avatar" do
    let(:user) { FactoryBot.create(:user) }

    it { should have_one_attached(:avatar) }

    it "is optional" do
      expect(user.avatar).not_to be_attached
      expect(user).to be_valid
    end

    it "accepts a PNG image" do
      user.avatar.attach(fixture_file_upload("avatar.png", "image/png"))
      expect(user).to be_valid
    end

    it "rejects files that are not images" do
      user.avatar.attach(fixture_file_upload("avatar.txt", "text/plain"))
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("deve ser PNG, JPG ou WEBP")
    end

    it "rejects images bigger than 2 MB" do
      png_header = File.binread(file_fixture("avatar.png"))
      io = StringIO.new(png_header + ("0" * 2.megabytes))
      user.avatar.attach(io: io, filename: "big.png", content_type: "image/png")
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("deve ter no máximo 2 MB")
    end

    it "removes the avatar when remove_avatar is set" do
      user.avatar.attach(fixture_file_upload("avatar.png", "image/png"))
      user.update!(remove_avatar: true)
      expect(user.reload.avatar).not_to be_attached
    end
  end
end
