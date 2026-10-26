require "rails_helper"

RSpec.describe BorrowingRemindersJob do
  let(:today) { Date.current }

  def borrow(book, due_on:, returned_on: nil)
    Borrowing.create!(reader: readers(:bob), book: book, borrowed_on: due_on - 30.days, due_on: due_on,
      returned_on: returned_on)
  end

  it "sends a due soon reminder 3 days before the due date" do
    borrowing = borrow(books(:hobbit), due_on: today + 3.days)

    expect { described_class.perform_now }
      .to have_enqueued_mail(BorrowingMailer, :due_soon).with(params: { borrowing: borrowing }, args: []).once
  end

  it "sends a due today reminder on the due date" do
    borrowing = borrow(books(:hobbit), due_on: today)

    expect { described_class.perform_now }
      .to have_enqueued_mail(BorrowingMailer, :due_today).with(params: { borrowing: borrowing }, args: []).once
  end

  it "skips other due dates and returned borrowings" do
    borrow(books(:hobbit), due_on: today + 2.days)
    borrow(books(:solaris), due_on: today + 3.days, returned_on: today)

    expect { described_class.perform_now }.not_to have_enqueued_mail
  end

  it "checks due dates relative to the given date" do
    borrowing = borrow(books(:hobbit), due_on: today + 10.days)

    expect { described_class.perform_now(today + 7.days) }
      .to have_enqueued_mail(BorrowingMailer, :due_soon).with(params: { borrowing: borrowing }, args: [])
  end
end
