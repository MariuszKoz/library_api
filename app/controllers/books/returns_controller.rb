class Books::ReturnsController < ApplicationController
  include BorrowingRendering

  def create
    book = Book.find(params[:book_id])
    borrowing = book.active_borrowing
    return render json: { error: "Book is not borrowed" }, status: :unprocessable_content unless borrowing

    if borrowing.update(returned_on: Date.current)
      render json: borrowing_json(borrowing)
    else
      render json: { errors: borrowing.errors }, status: :unprocessable_content
    end
  end
end
