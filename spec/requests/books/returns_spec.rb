require "rails_helper"

RSpec.describe "Book returns", type: :request do
  let(:json) { response.parsed_body }

  describe "POST /books/:book_id/return" do
    it "closes the active borrowing" do
      post book_return_path(books(:dune)), as: :json

      expect(response).to have_http_status(:ok)
      expect(json).to include("id" => borrowings(:active).id, "returned_on" => Date.current.iso8601)
      expect(borrowings(:active).reload).not_to be_active
      expect(books(:dune).reload.status).to eq("available")
    end

    it "rejects a book returned twice" do
      post book_return_path(books(:dune)), as: :json
      post book_return_path(books(:dune)), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Book is not borrowed")
    end

    it "rejects a book that is not borrowed" do
      post book_return_path(books(:hobbit)), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("error" => "Book is not borrowed")
    end

    it "returns 404 for an unknown book" do
      post book_return_path(book_id: 0), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
