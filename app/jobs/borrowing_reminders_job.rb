class BorrowingRemindersJob < ApplicationJob
  DUE_SOON = 3.days

  queue_as :default

  def perform(date = Date.current)
    Borrowing.active.where(due_on: date + DUE_SOON).find_each do |borrowing|
      BorrowingMailer.with(borrowing: borrowing).due_soon.deliver_later
    end

    Borrowing.active.where(due_on: date).find_each do |borrowing|
      BorrowingMailer.with(borrowing: borrowing).due_today.deliver_later
    end
  end
end
