namespace :db do
  # Modo banco único: com DATABASE_URL (ex.: Postgres do Fly.io) existe só o banco principal,
  # e o usuário normalmente não pode criar outros. Então Solid Cache/Queue/Cable usam o mesmo
  # banco, e as tabelas deles são criadas aqui a partir de db/*_schema.rb.
  # Sem DATABASE_URL (Kamal), cada um tem o próprio banco e esta task não faz nada.
  desc "Cria as tabelas do Solid Cache/Queue/Cable no banco principal (modo DATABASE_URL)"
  task load_solid_schemas: :environment do
    next if ENV["DATABASE_URL"].blank?

    connection = ActiveRecord::Base.connection
    {
      "solid_cache_entries" => "cache_schema.rb",
      "solid_queue_jobs" => "queue_schema.rb",
      "solid_cable_messages" => "cable_schema.rb"
    }.each do |table, file|
      next if connection.table_exists?(table)

      load Rails.root.join("db", file)
    end
  end
end
