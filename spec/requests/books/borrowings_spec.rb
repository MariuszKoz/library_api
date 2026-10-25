require "rails_helper"

RSpec.describe "Book borrowings", type: :request do
  let(:json) { response.parsed_body }

  describe "POST /books/:book_id/borrowing" do
    it "lends the book to the reader for 30 days" do
      expect {
        post book_borrowing_path(books(:hobbit)), params: { card_number: readers(:bob).card_number }, as: :json
      }.to change(Borrowing, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json).to include(
        "borrowed_on" => Date.current.iso8601,
        "due_on" => (Date.current + 30.days).iso8601,
        "returned_on" => nil,
        "book" => { "id" => books(:hobbit).id, "serial_number" => "200003", "title" => "The Hobbit" },
        "reader" => { "id" => readers(:bob).id, "card_number" => "100002", "name" => "Bob Wisniewski" }
      )
      expect(books(:hobbit).reload.status).to eq("borrowed")
    end

    it "lends a book again after it was returned" do
      post book_borrowing_path(books(:solaris)), params: { card_number: readers(:bob).card_number }, as: :json

      expect(response).to have_http_status(:created)
    end

    it "rejects a book that is already borrowed" do
      expect {
        post book_borrowing_path(books(:dune)), params: { card_number: readers(:bob).card_number }, as: :json
      }.not_to change(Borrowing, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["book_id"]).to include("is already borrowed")
    end

    it "rejects a concurrent borrowing caught by the database" do
      # Simulates a race: the uniqueness validation passes, the partial unique index rejects the insert
      allow_any_instance_of(Borrowing).to receive(:valid?).and_wrap_original do |original, *args|
        original.call(*args)
        true
      end

      post book_borrowing_path(books(:dune)), params: { card_number: readers(:bob).card_number }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["book_id"]).to include("is already borrowed")
    end

    it "does not create a borrowing for an unknown card number" do
      expect {
        post book_borrowing_path(books(:hobbit)), params: { card_number: "999999" }, as: :json
      }.not_to change(Borrowing, :count)

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Reader not found")
    end

    [ {}, { card_number: "" } ].each do |params|
      it "returns 400 for #{params.inspect}" do
        post book_borrowing_path(books(:hobbit)), params: params, as: :json

        expect(response).to have_http_status(:bad_request)
      end
    end

    it "returns 404 for an unknown book" do
      post book_borrowing_path(book_id: 0), params: { card_number: readers(:bob).card_number }, as: :json

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Not found")
    end
  end
end
