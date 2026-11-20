require "rails_helper"

RSpec.describe "CORS", type: :request do
  around do |example|
    original = ENV["CORS_ORIGINS"]
    example.run
  ensure
    original.nil? ? ENV.delete("CORS_ORIGINS") : ENV["CORS_ORIGINS"] = original
  end

  def preflight(origin)
    process :options, rails_health_check_path, headers: { "Origin" => origin, "Access-Control-Request-Method" => "GET" }
  end

  it "allows only the origins listed in CORS_ORIGINS" do
    ENV["CORS_ORIGINS"] = "https://app.exemplo.com, https://admin.exemplo.com"

    preflight("https://admin.exemplo.com")
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://admin.exemplo.com")
    expect(response.headers["Access-Control-Allow-Credentials"]).to be_nil

    preflight("https://malicioso.com")
    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end

  it "allows no origin when CORS_ORIGINS is not set" do
    ENV.delete("CORS_ORIGINS")
    preflight("https://app.exemplo.com")
    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil

    get root_path, headers: { "Origin" => "https://app.exemplo.com" }
    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end
end
