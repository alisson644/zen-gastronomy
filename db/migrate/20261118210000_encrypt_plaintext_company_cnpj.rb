# Empresas criadas antes de `encrypts :cnpj` têm o CNPJ em texto puro,
# o que faz a leitura estourar ActiveRecord::Encryption::Errors::Decryption.
# Cifra esses valores com a chave atual; valores já cifrados ou vazios não mudam.
class EncryptPlaintextCompanyCnpj < ActiveRecord::Migration[8.0]
  class LegacyCompany < ActiveRecord::Base
    self.table_name = "companies"
    encrypts :cnpj
  end

  def up
    encryptor = ActiveRecord::Encryption.encryptor
    encrypted_type = LegacyCompany.type_for_attribute(:cnpj)

    select_rows("SELECT id, cnpj FROM companies WHERE cnpj IS NOT NULL AND cnpj <> ''").each do |id, raw|
      next if encryptor.encrypted?(raw)

      ciphertext = encrypted_type.serialize(raw)
      execute "UPDATE companies SET cnpj = #{connection.quote(ciphertext)} WHERE id = #{id.to_i}"
    end
  end

  def down
    # Irreversível de propósito: não voltamos a gravar CNPJ em texto puro.
  end
end
