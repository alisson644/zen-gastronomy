require "rails_helper"

RSpec.describe "Security headers", type: :request do
  before { get root_path }

  it "sends a restrictive Content-Security-Policy with a script nonce" do
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("default-src 'self'", "frame-ancestors 'none'", "object-src 'none'", "base-uri 'self'")
    expect(csp).to match(/script-src 'self' https:\/\/cdn\.jsdelivr\.net 'nonce-[^']+'/)
    expect(response.body).to match(/<script[^>]+src="\/assets\/application-[^"]+\.js"[^>]+nonce="/)
  end

  it "disables powerful browser features" do
    expect(response.headers["Permissions-Policy"]).to include("camera=()", "microphone=()", "geolocation=()")
  end

  it "pins the CDN script to an exact version" do
    expect(response.body).not_to include("@tailwindplus/elements@1\"")
    expect(response.body).to match(%r{@tailwindplus/elements@\d+\.\d+\.\d+})
  end
end
