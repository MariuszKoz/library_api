require "rails_helper"

RSpec.describe "Books", type: :request do
  let(:json) { response.parsed_body }

  describe "GET /books" do
    it "lists all books with their status" do
      get books_path, as: :json

      expect(response).to have_http_status(:ok)
      expect(json.map { |book| [ book["title"], book["status"] ] }).to contain_exactly(
        [ "Dune", "borrowed" ], [ "Solaris", "available" ], [ "The Hobbit", "available" ]
      )
      expect(json.first.keys).to contain_exactly("id", "serial_number", "title", "author", "status")
    end
  end

  describe "GET /books/:id" do
    it "returns the book with its borrowing history" do
      get book_path(books(:solaris)), as: :json

      expect(response).to have_http_status(:ok)
      expect(json).to include("serial_number" => "200002", "title" => "Solaris", "status" => "available")
      expect(json["borrowings"]).to contain_exactly(
        "id" => borrowings(:returned).id,
        "borrowed_on" => borrowings(:returned).borrowed_on.iso8601,
        "due_on" => borrowings(:returned).due_on.iso8601,
        "returned_on" => borrowings(:returned).returned_on.iso8601,
        "reader" => { "id" => readers(:alice).id, "card_number" => "100001", "name" => "Alice Nowak" }
      )
    end

    it "lists the newest borrowing first" do
      older = Borrowing.create!(reader: readers(:bob), book: books(:solaris),
        borrowed_on: 90.days.ago.to_date, returned_on: 70.days.ago.to_date)

      get book_path(books(:solaris)), as: :json

      expect(json["borrowings"].pluck("id")).to eq([ borrowings(:returned).id, older.id ])
    end

    it "marks a borrowed book" do
      get book_path(books(:dune)), as: :json

      expect(json["status"]).to eq("borrowed")
      expect(json["borrowings"].pluck("returned_on")).to eq([ nil ])
    end

    it "returns an empty history for a book never borrowed" do
      get book_path(books(:hobbit)), as: :json

      expect(json["borrowings"]).to eq([])
    end

    it "returns 404 for an unknown book" do
      get book_path(id: 0), as: :json

      expect(response).to have_http_status(:not_found)
      expect(json).to eq("error" => "Not found")
    end
  end

  describe "POST /books" do
    let(:params) { { book: { serial_number: "000777", title: "Lalka", author: "Boleslaw Prus" } } }

    it "registers a new book" do
      expect { post books_path, params: params, as: :json }.to change(Book, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.location).to eq(book_url(Book.last))
      expect(json).to include("serial_number" => "000777", "title" => "Lalka",
        "author" => "Boleslaw Prus", "status" => "available")
    end

    it "rejects invalid attributes" do
      params[:book].merge!(serial_number: "12345", title: "")

      expect { post books_path, params: params, as: :json }.not_to change(Book, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"].keys).to contain_exactly("serial_number", "title")
    end

    it "rejects a duplicate serial number" do
      params[:book][:serial_number] = books(:dune).serial_number

      post books_path, params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["serial_number"]).to include("has already been taken")
    end

    it "accepts attributes without the book key" do
      post books_path, params: params[:book], as: :json

      expect(response).to have_http_status(:created)
    end

    it "returns 400 without book attributes" do
      post books_path, params: {}, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /books/:id" do
    it "removes a book without borrowings" do
      expect { delete book_path(books(:hobbit)), as: :json }.to change(Book, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "keeps a book with borrowing history, even if all were returned" do
      expect { delete book_path(books(:solaris)), as: :json }.not_to change(Book, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["base"]).to include("Cannot delete record because dependent borrowings exist")
    end

    it "returns 404 for an unknown book" do
      delete book_path(id: 0), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
