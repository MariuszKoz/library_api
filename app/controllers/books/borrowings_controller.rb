class Books::BorrowingsController < ApplicationController
  include BorrowingRendering

  def create
    book = Book.find(params[:book_id])
    reader = Reader.find_by(card_number: params.require(:card_number))
    return render json: { error: "Reader not found" }, status: :not_found unless reader

    borrowing = book.borrowings.new(reader: reader)

    if borrowing.save
      render json: borrowing_json(borrowing), status: :created
    else
      render json: { errors: borrowing.errors }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { errors: { book_id: [ "is already borrowed" ] } }, status: :unprocessable_content
  end
end
