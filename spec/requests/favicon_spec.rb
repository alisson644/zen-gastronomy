require "rails_helper"

RSpec.describe "Favicon", type: :request do
  it "uses only the Zen Gastronomy logo as the browser tab icon" do
    get root_path

    expect(response.body).to include('<link rel="icon" href="/icon.png" type="image/png">')
    expect(response.body).not_to include("icon.svg")
    expect(Rails.public_path.join("icon.svg")).not_to exist
  end

  it "ships a 512x512 PNG icon (required by the PWA manifest)" do
    png = File.binread(Rails.public_path.join("icon.png"), 24)
    width, height = png[16, 8].unpack("NN")

    expect(png[0, 8]).to eq("\x89PNG\r\n\x1A\n".b)
    expect([ width, height ]).to eq([ 512, 512 ])
  end
end
