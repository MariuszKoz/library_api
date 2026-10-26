class BorrowingMailer < ApplicationMailer
  before_action :set_borrowing

  def due_soon
    mail to: @borrowing.reader.email, subject: "Reminder: \"#{@borrowing.book.title}\" is due on #{@borrowing.due_on}"
  end

  def due_today
    mail to: @borrowing.reader.email, subject: "Today is the last day to return \"#{@borrowing.book.title}\""
  end

  private
    def set_borrowing
      @borrowing = params[:borrowing]
    end
end
