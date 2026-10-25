require "rails_helper"

RSpec.describe Borrowing do
  subject(:borrowing) { described_class.new(reader: readers(:bob), book: books(:hobbit)) }

  describe "dates" do
    it "defaults borrowed_on to today and due_on to 30 days later" do
      borrowing.save!

      expect(borrowing.borrowed_on).to eq(Date.current)
      expect(borrowing.due_on).to eq(Date.current + 30.days)
    end

    it "computes due_on from a given borrowed_on" do
      borrowing.borrowed_on = Date.new(2026, 1, 15)

      expect(borrowing).to be_valid
      expect(borrowing.due_on).to eq(Date.new(2026, 2, 14))
    end

    it "keeps an explicitly given due_on" do
      borrowing.borrowed_on = Date.new(2026, 1, 15)
      borrowing.due_on = Date.new(2026, 1, 20)

      expect(borrowing).to be_valid
      expect(borrowing.due_on).to eq(Date.new(2026, 1, 20))
    end

    it "requires due_on after borrowed_on" do
      borrowing.borrowed_on = Date.new(2026, 1, 15)
      borrowing.due_on = Date.new(2026, 1, 15)

      expect(borrowing).not_to be_valid
      expect(borrowing.errors).to include(:due_on)
    end

    it "rejects returned_on before borrowed_on" do
      borrowing.borrowed_on = Date.new(2026, 1, 15)
      borrowing.returned_on = Date.new(2026, 1, 14)

      expect(borrowing).not_to be_valid
      expect(borrowing.errors).to include(:returned_on)
    end
  end

  it "requires a reader and a book" do
    borrowing = described_class.new

    expect(borrowing).not_to be_valid
    expect(borrowing.errors).to include(:reader, :book)
  end

  describe "active and returned" do
    it "is active until returned" do
      expect(borrowings(:active)).to be_active
      expect(borrowings(:returned)).not_to be_active
    end

    it "scopes borrowings by state" do
      expect(described_class.active).to contain_exactly(borrowings(:active))
      expect(described_class.returned).to contain_exactly(borrowings(:returned))
    end

    it "can be returned" do
      borrowing = borrowings(:active)

      expect(borrowing.update(returned_on: Date.current)).to be(true)
      expect(borrowing).not_to be_active
    end
  end

  describe "one active borrowing per book" do
    it "rejects a second active borrowing of the same book" do
      borrowing.book = books(:dune)

      expect(borrowing).not_to be_valid
      expect(borrowing.errors[:book_id]).to include("is already borrowed")
    end

    it "allows borrowing a book again after it was returned" do
      borrowing.book = books(:solaris)

      expect(borrowing).to be_valid
    end
  end

  describe "database constraints" do
    it "reject a second active borrowing of the same book" do
      borrowing.book = books(:dune)
      borrowing.due_on = Date.current + 30.days

      expect { borrowing.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "reject due_on not after borrowed_on" do
      borrowing.due_on = borrowing.borrowed_on

      expect { borrowing.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
