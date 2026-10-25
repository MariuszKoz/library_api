require "rails_helper"

RSpec.describe "Readers", type: :request do
  let(:json) { response.parsed_body }
  let(:params) { { reader: { card_number: "000123", name: "Jan Kowalski", email: "Jan@Example.com" } } }

  describe "POST /readers" do
    it "creates a reader" do
      expect { post readers_path, params: params, as: :json }.to change(Reader, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include("card_number" => "000123", "name" => "Jan Kowalski", "email" => "jan@example.com")
    end

    it "rejects invalid attributes" do
      params[:reader].merge!(card_number: "123", name: "", email: "jan@")

      expect { post readers_path, params: params, as: :json }.not_to change(Reader, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].keys).to contain_exactly("card_number", "name", "email")
    end

    it "rejects a duplicate card number and email" do
      params[:reader].merge!(card_number: readers(:alice).card_number, email: "ALICE@example.com")

      post readers_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("card_number" => [ "has already been taken" ],
        "email" => [ "has already been taken" ])
    end

    it "returns 400 without reader attributes" do
      post readers_path, params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end
end
