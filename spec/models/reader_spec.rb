require "rails_helper"

RSpec.describe Reader do
  subject(:reader) { described_class.new(card_number: "123456", name: "Jan Kowalski", email: "jan@example.com") }

  it "is valid with a 6 digit card number, name and email" do
    expect(reader).to be_valid
  end

  describe "#card_number" do
    it "keeps leading zeros" do
      reader.card_number = "000123"
      reader.save!

      expect(reader.reload.card_number).to eq("000123")
    end

    [ nil, "", "12345", "1234567", "12a456", " 12345" ].each do |card_number|
      it "is invalid when #{card_number.inspect}" do
        reader.card_number = card_number

        expect(reader).not_to be_valid
      end
    end

    it "must be unique" do
      reader.card_number = readers(:alice).card_number

      expect(reader).not_to be_valid
      expect(reader.errors[:card_number]).to include("has already been taken")
    end
  end

  describe "#name" do
    it "is required" do
      reader.name = ""

      expect(reader).not_to be_valid
    end
  end

  describe "#email" do
    [ nil, "", "not-an-email", "jan@" ].each do |email|
      it "is invalid when #{email.inspect}" do
        reader.email = email

        expect(reader).not_to be_valid
      end
    end

    it "is normalized" do
      reader.email = "  Jan@Example.COM "

      expect(reader.email).to eq("jan@example.com")
    end

    it "must be unique regardless of case" do
      reader.email = "ALICE@example.com"

      expect(reader).not_to be_valid
      expect(reader.errors[:email]).to include("has already been taken")
    end
  end

  describe "#destroy" do
    it "is blocked while the reader has borrowings" do
      expect(readers(:alice).destroy).to be(false)
      expect(described_class.exists?(readers(:alice).id)).to be(true)
    end
  end

  describe "database constraints" do
    it "reject a duplicate card number" do
      reader.card_number = readers(:alice).card_number

      expect { reader.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "reject an invalid card number" do
      reader.card_number = "12345"

      expect { reader.save(validate: false) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
