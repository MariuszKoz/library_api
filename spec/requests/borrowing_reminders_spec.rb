require "rails_helper"

RSpec.describe "Borrowing reminders", type: :request do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:book) { books(:hobbit) }

  before do
    ActionMailer::Base.deliveries.clear
    post book_borrowing_path(book), params: { card_number: readers(:bob).card_number }, as: :json
  end

  it "sends a reminder 3 days before the due date" do
    travel_to(27.days.from_now) do
      expect {
        perform_enqueued_jobs { BorrowingRemindersJob.perform_now }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([ "bob@example.com" ])
    expect(mail.subject).to include("The Hobbit")
  end

  it "sends a reminder on the due date" do
    travel_to(30.days.from_now) do
      expect {
        perform_enqueued_jobs { BorrowingRemindersJob.perform_now }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  it "does not send a reminder when the book was returned" do
    post book_return_path(book), as: :json

    travel_to(27.days.from_now) do
      expect {
        perform_enqueued_jobs { BorrowingRemindersJob.perform_now }
      }.not_to change { ActionMailer::Base.deliveries.count }
    end
  end
end
