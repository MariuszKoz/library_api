require "rails_helper"

RSpec.describe Book do
  subject(:book) { described_class.new(serial_number: "654321", title: "Lalka", author: "Boleslaw Prus") }

  it "is valid with a 6 digit serial number, title and author" do
    expect(book).to be_valid
  end

  describe "#serial_number" do
    [ nil, "", "12345", "1234567", "12a456" ].each do |serial_number|
      it "is invalid when #{serial_number.inspect}" do
        book.serial_number = serial_number

        expect(book).not_to be_valid
      end
    end

    it "must be unique" do
      book.serial_number = books(:dune).serial_number

      expect(book).not_to be_valid
      expect(book.errors[:serial_number]).to include("has already been taken")
    end
  end

  it "requires a title and an author" do
    book.title = ""
    book.author = ""

    expect(book).not_to be_valid
    expect(book.errors).to include(:title, :author)
  end

  describe "#status" do
    it "is borrowed while the book has an active borrowing" do
      expect(books(:dune).status).to eq("borrowed")
    end

    it "is available when all borrowings were returned" do
      expect(books(:solaris).status).to eq("available")
    end

    it "is available without borrowings" do
      expect(books(:hobbit).status).to eq("available")
    end
  end

  describe "#destroy" do
    it "is blocked while the book has borrowings" do
      expect(books(:solaris).destroy).to be(false)
    end

    it "succeeds without borrowings" do
      expect(books(:hobbit).destroy).to be_truthy
    end
  end

  describe "database constraints" do
    it "reject a duplicate serial number" do
      book.serial_number = books(:dune).serial_number

      expect { book.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "reject an invalid serial number" do
      book.serial_number = "abcdef"

      expect { book.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
