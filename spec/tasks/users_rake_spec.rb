require "rails_helper"
require "rake"

RSpec.describe "users:make_admin" do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  let(:task) { Rake::Task["users:make_admin"] }

  after { task.reenable }

  it "promotes the user with the given e-mail to system admin" do
    user = create(:user, email: "chefe@example.com")

    expect { task.invoke("chefe@example.com") }.to output(/chefe@example.com/).to_stdout
    expect(user.reload).to be_system_admin
  end

  it "fails for an unknown e-mail" do
    expect { task.invoke("ninguem@example.com") }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
