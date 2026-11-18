require "rails_helper"
require Rails.root.join("db/migrate/20261118210000_encrypt_plaintext_company_cnpj")

RSpec.describe EncryptPlaintextCompanyCnpj do
  def raw_cnpj(company)
    Company.connection.select_value("SELECT cnpj FROM companies WHERE id = #{company.id.to_i}")
  end

  it "encrypts cnpj values saved before `encrypts :cnpj` existed" do
    legacy = create(:company)
    # SQL puro, como as linhas gravadas antes de `encrypts :cnpj`
    Company.connection.execute("UPDATE companies SET cnpj = '11.222.333/0001-44' WHERE id = #{legacy.id.to_i}")

    expect { Company.find(legacy.id).cnpj }.to raise_error(ActiveRecord::Encryption::Errors::Decryption)

    described_class.new.up

    expect(Company.find(legacy.id).cnpj).to eq("11.222.333/0001-44")
    expect(raw_cnpj(legacy)).not_to eq("11.222.333/0001-44")
  end

  it "keeps already encrypted and blank values untouched" do
    encrypted = create(:company, cnpj: "99.888.777/0001-66")
    blank = create(:company, cnpj: nil)
    before = raw_cnpj(encrypted)

    described_class.new.up

    expect(raw_cnpj(encrypted)).to eq(before)
    expect(Company.find(encrypted.id).cnpj).to eq("99.888.777/0001-66")
    expect(Company.find(blank.id).cnpj).to be_nil
  end
end
