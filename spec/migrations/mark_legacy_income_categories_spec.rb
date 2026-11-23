require "rails_helper"
require Rails.root.join("db/migrate/20261123120000_mark_legacy_income_categories")

RSpec.describe MarkLegacyIncomeCategories do
  it "marks legacy 'Entrada de caixa' categories as income" do
    company = create(:company)
    legacy = company.categories.find_by!(name: "Entrada de caixa")
    # Empresas criadas antes do seed gravar is_income: true
    legacy.update_column(:is_income, false)

    described_class.new.up

    expect(legacy.reload.is_income).to be(true)
  end

  it "leaves expense categories untouched" do
    company = create(:company)

    described_class.new.up

    expect(company.categories.where(is_income: true).pluck(:name)).to eq([ "Entrada de caixa" ])
  end
end
