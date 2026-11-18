class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :subcategories, dependent: :destroy
  has_many :movements, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :cnpj, length: { maximum: 20 }, allow_blank: true

  encrypts :cnpj

  after_create { Role.create_defaults_for!(self) }
  after_create_commit :create_settings_initial



  private
  def create_settings_initial
    # Create categories defaults
    category_01 = Category.create(name: "Entrada de caixa", company_id: self.id, is_income: true)
    category_02 = Category.create(name: "Despesas Variáveis - CMV", company_id: self.id)
    category_03 = Category.create(name: "CMV - Bebidas", company_id: self.id)
    category_04 = Category.create(name: "Despesas fixas - CMO", company_id: self.id)
    category_05 = Category.create(name: "Contas Publicas", company_id: self.id)
    category_06 = Category.create(name: "Despesas de Produção", company_id: self.id)
    category_07 = Category.create(name: "Custo com Ocupação", company_id: self.id)
    category_08 = Category.create(name: "Despesas com Marketing", company_id: self.id)
    category_09 = Category.create(name: "Despesas de Manuntenção", company_id: self.id)
    category_10 = Category.create(name: "Despesas de Eventuais", company_id: self.id)
    category_11 = Category.create(name: "Despesas de Administrativas", company_id: self.id)
    category_12 = Category.create(name: "Despesas de Financeiras", company_id: self.id)

    # Create Subcategories In
    # 01 - Entrada de Caixa
    Subcategory.create(name: "Dinheiro", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Crédito AMEX", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Crédito Credsystem/Mais", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Crédito Elo", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Crédito Hipercard", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Crédito Mastercard", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Crédito Sorocred", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Crédito Visa", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Débito Elo", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Débito Mastercard", company_id: self.id, category: category_01)
    Subcategory.create(name: "Cartão de Débito Visa", company_id: self.id, category: category_01)
    Subcategory.create(name: "Consumo do Dono", company_id: self.id, category: category_01)
    Subcategory.create(name: "Pix", company_id: self.id, category: category_01)

    # Create Suvcategories out
    # 02 - Despesas Variáveis - CMV
    Subcategory.create(name: "Congelados", company_id: self.id, category: category_02)
    Subcategory.create(name: "Estocáveis", company_id: self.id, category: category_02)
    Subcategory.create(name: "Hortifruti", company_id: self.id, category: category_02)
    Subcategory.create(name: "Proteínas", company_id: self.id, category: category_02)
    Subcategory.create(name: "Resfriados", company_id: self.id, category: category_02)

    # 03 - CMV - Bebidas
    Subcategory.create(name: "Bebidas Não Alcóolicas", company_id: self.id, category: category_03)
    Subcategory.create(name: "Cervejas", company_id: self.id, category: category_03)
    Subcategory.create(name: "Destilados / Drinks", company_id: self.id, category: category_03)
    Subcategory.create(name: "Vinhos", company_id: self.id, category: category_03)

    # 04 - Despesas fixas - CMO
    Subcategory.create(name: "Auxílio Uniforme", company_id: self.id, category: category_04)
    Subcategory.create(name: "Décimo Terceiro Salário", company_id: self.id, category: category_04)
    Subcategory.create(name: "Despesas com Admissão e Demissão", company_id: self.id, category: category_04)
    Subcategory.create(name: "Férias", company_id: self.id, category: category_04)
    Subcategory.create(name: "FGTS", company_id: self.id, category: category_04)
    Subcategory.create(name: "Gorjeta", company_id: self.id, category: category_04)
    Subcategory.create(name: "INSS", company_id: self.id, category: category_04)
    Subcategory.create(name: "IRRF", company_id: self.id, category: category_04)
    Subcategory.create(name: "Plano de Saúde", company_id: self.id, category: category_04)
    Subcategory.create(name: "Pró-labore", company_id: self.id, category: category_04)
    Subcategory.create(name: "Salários", company_id: self.id, category: category_04)
    Subcategory.create(name: "Seguro de Vida", company_id: self.id, category: category_04)
    Subcategory.create(name: "Vale Refeição", company_id: self.id, category: category_04)
    Subcategory.create(name: "Vale Transporte", company_id: self.id, category: category_04)

    # 05 - Contas Publicas
    Subcategory.create(name: "Água", company_id: self.id, category: category_05)
    Subcategory.create(name: "Eletricidade", company_id: self.id, category: category_05)
    Subcategory.create(name: "Internet", company_id: self.id, category: category_05)
    Subcategory.create(name: "Lixo", company_id: self.id, category: category_05)
    Subcategory.create(name: "Telefone", company_id: self.id, category: category_05)

    # 06 - Despesas de Produção
    Subcategory.create(name: "Flores", company_id: self.id, category: category_06)
    Subcategory.create(name: "Gás", company_id: self.id, category: category_06)
    Subcategory.create(name: "Gelo", company_id: self.id, category: category_06)
    Subcategory.create(name: "Higiene, Limpeza e Embalagens", company_id: self.id, category: category_06)
    Subcategory.create(name: "Sistema", company_id: self.id, category: category_06)

    # 07 - Custo de Ocupação
    Subcategory.create(name: "Aluguel", company_id: self.id, category: category_07)
    Subcategory.create(name: "IPTU", company_id: self.id, category: category_07)

    # 08 - Despesas com Marketing
    Subcategory.create(name: "Ações de Marketing", company_id: self.id, category: category_08)
    Subcategory.create(name: "Anúncios", company_id: self.id, category: category_08)
    Subcategory.create(name: "Guia", company_id: self.id, category: category_08)
    Subcategory.create(name: "Mídias Sociais", company_id: self.id, category: category_08)
    Subcategory.create(name: "Permutas ", company_id: self.id, category: category_08)

    # 09 - Despesas de Manuntenção
    Subcategory.create(name: "Máquinas e Equipamentos", company_id: self.id, category: category_09)
    Subcategory.create(name: "Predial", company_id: self.id, category: category_09)
    Subcategory.create(name: "Preventiva", company_id: self.id, category: category_09)

    # 10 - Despesas Eventuais
    Subcategory.create(name: "Cardápio", company_id: self.id, category: category_10)
    Subcategory.create(name: "Despesas com Veículo", company_id: self.id, category: category_10)
    Subcategory.create(name: "Frete", company_id: self.id, category: category_10)
    Subcategory.create(name: "Material de Escritório e Informática", company_id: self.id, category: category_10)
    Subcategory.create(name: "Utensílios e Equipamentos", company_id: self.id, category: category_10)

    # 11 - Despesas Administrativas
    Subcategory.create(name: "Contador", company_id: self.id, category: category_11)
    Subcategory.create(name: "Taxa de Serviço 10%", company_id: self.id, category: category_11)
    Subcategory.create(name: "Taxa Ifood 12%", company_id: self.id, category: category_11)

    # 12 - Despesas Financeiras
    Subcategory.create(name: "Alvará", company_id: self.id, category: category_12)
    Subcategory.create(name: "Parcelamento", company_id: self.id, category: category_12)
    Subcategory.create(name: "Renegociação de Dívida", company_id: self.id, category: category_12)
    Subcategory.create(name: "Simples / MEI", company_id: self.id, category: category_12)
    Subcategory.create(name: "Tarifa Bancária", company_id: self.id, category: category_12)
    Subcategory.create(name: "Taxa de Antecipação", company_id: self.id, category: category_12)


    # Create account cash
    Account.create(name: "Caixa Dinheiro", account_type: :caixa, current_balance: 0, initial_balance: 0, company_id: self.id)
  end
end
