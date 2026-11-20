require "rails_helper"
require "rake"

# Modo banco único (DATABASE_URL, ex.: Fly.io): as tabelas do Solid Cache/Queue/Cable
# ficam no banco principal.
RSpec.describe "db:load_solid_schemas" do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  let(:task) { Rake::Task["db:load_solid_schemas"] }
  let(:connection) { ActiveRecord::Base.connection }
  let(:tables) { %w[solid_cache_entries solid_queue_jobs solid_cable_messages] }

  around do |example|
    original = ENV["DATABASE_URL"]
    example.run
  ensure
    original.nil? ? ENV.delete("DATABASE_URL") : ENV["DATABASE_URL"] = original
  end

  after { task.reenable }

  it "creates the Solid tables in the primary database when DATABASE_URL is set" do
    ENV["DATABASE_URL"] = "postgres://usuario@banco/zen"
    expect { task.invoke }.to output(/solid_queue_jobs/).to_stdout

    tables.each { |table| expect(connection.table_exists?(table)).to be(true), table }
  end

  it "is idempotent" do
    ENV["DATABASE_URL"] = "postgres://usuario@banco/zen"
    task.invoke
    task.reenable
    expect { task.invoke }.not_to raise_error
  end

  it "does nothing with separate databases (no DATABASE_URL)" do
    ENV.delete("DATABASE_URL")
    task.invoke
    tables.each { |table| expect(connection.table_exists?(table)).to be(false), table }
  end
end
