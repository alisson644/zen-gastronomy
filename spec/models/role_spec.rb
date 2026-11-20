require "rails_helper"

RSpec.describe Role, type: :model do
  let(:company) { create(:company) }

  subject { build(:role, company: company) }

  it { should belong_to(:company).optional }
  it { should have_many(:users).dependent(:restrict_with_error) }
  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).scoped_to(:company_id) }

  describe "default roles of a company" do
    it "creates Dono and Administrativo for every new company" do
      expect(company.roles.pluck(:key)).to match_array(%w[dono administrativo])
      expect(company.roles.find_by!(key: "administrativo").permissions).to match_array(%w[financial.view movements.create])
    end

    it "keeps each company's roles separate" do
      other = create(:company)
      expect(company.roles.find_by!(key: "dono")).not_to eq(other.roles.find_by!(key: "dono"))
    end

    it "lets two companies use the same role name" do
      create(:role, company: company, name: "Caixa")
      expect(build(:role, company: create(:company), name: "Caixa")).to be_valid
    end
  end

  describe "permissions" do
    it "rejects permissions outside the catalog" do
      role = build(:role, company: company, permissions: %w[financial.view hack.everything])
      expect(role).not_to be_valid
    end

    it "does not allow global permissions in a company role" do
      role = build(:role, company: company, permissions: %w[financial.view companies.view_all])
      expect(role).not_to be_valid
      expect(role.errors[:permissions]).to be_present
    end

    it "ignores blank entries sent by checkbox forms" do
      expect(build(:role, company: company, permissions: [ "", "financial.view" ]).permissions).to eq(%w[financial.view])
    end

    it "lets companies grant the stock permissions" do
      expect(Permission::COMPANY).to include("stock.view", "stock.entries", "stock.count", "products.manage", "suppliers.manage")
    end

    it "gives the Dono every company permission, even ones added to the catalog later" do
      dono = company.roles.find_by!(key: "dono")
      dono.update_column(:permissions, [])
      Permission::COMPANY.each { |permission| expect(dono.allows?(permission)).to be true }
      expect(dono.allows?("companies.view_all")).to be false
    end
  end

  describe ".admin!" do
    it "is a single global role with every permission" do
      admin = Role.admin!
      expect(Role.admin!).to eq(admin)
      expect(admin.company).to be_nil
      Permission::ALL.each_key { |permission| expect(admin.allows?(permission)).to be true }
    end

    it "is never one of the company roles" do
      Role.admin!
      expect(company.roles.pluck(:key)).not_to include("admin")
    end
  end

  describe "destroy" do
    it "cannot destroy the default roles of a company" do
      %w[dono administrativo].each do |key|
        role = company.roles.find_by!(key: key)
        expect(role.destroy).to be false
      end
    end

    it "cannot destroy a role in use" do
      role = create(:role, company: company)
      create(:user, company: company, role: role)
      expect(role.destroy).to be false
    end

    it "destroys a custom role without users" do
      role = create(:role, company: company)
      expect { role.destroy }.to change(Role, :count).by(-1)
    end

    it "is removed together with its company" do
      create(:user, company: company)
      expect { company.destroy }.to change { Role.where(company_id: company.id).count }.to(0)
    end
  end
end
