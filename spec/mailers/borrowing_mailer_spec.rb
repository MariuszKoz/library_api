require "rails_helper"

RSpec.describe BorrowingMailer do
  let(:borrowing) { borrowings(:active) }

  describe "#due_soon" do
    subject(:mail) { described_class.with(borrowing: borrowing).due_soon }

    it "reminds the reader about the due date" do
      expect(mail.to).to eq([ "alice@example.com" ])
      expect(mail.from).to eq([ "library@example.com" ])
      expect(mail.subject).to eq("Reminder: \"Dune\" is due on #{borrowing.due_on}")
    end

    it "renders text and html parts with the book and due date" do
      [ mail.text_part, mail.html_part ].each do |part|
        expect(part.decoded).to include("Alice Nowak", "Dune", "Frank Herbert", "200001", borrowing.due_on.to_s)
      end
    end
  end

  describe "#due_today" do
    subject(:mail) { described_class.with(borrowing: borrowing).due_today }

    it "tells the reader that today is the last day" do
      expect(mail.to).to eq([ "alice@example.com" ])
      expect(mail.subject).to eq("Today is the last day to return \"Dune\"")
    end

    it "renders text and html parts with the book and due date" do
      [ mail.text_part, mail.html_part ].each do |part|
        expect(part.decoded).to include("Alice Nowak", "Dune", "200001", borrowing.due_on.to_s)
      end
    end
  end
end
