# Preview all emails at http://localhost:3000/rails/mailers/borrowing_mailer
class BorrowingMailerPreview < ActionMailer::Preview
  def due_soon
    BorrowingMailer.with(borrowing: borrowing(due_in: 3.days)).due_soon
  end

  def due_today
    BorrowingMailer.with(borrowing: borrowing(due_in: 0.days)).due_today
  end

  private
    def borrowing(due_in:)
      Borrowing.new(
        reader: Reader.new(name: "Paul Kravecki", email: "paul.kravecki@example.com"),
        book: Book.new(serial_number: "000777", title: "Ja Inkiwzytor", author: "Jacek Piekara"),
        borrowed_on: Date.current + due_in - Borrowing::LOAN_PERIOD,
        due_on: Date.current + due_in
      )
    end
end
