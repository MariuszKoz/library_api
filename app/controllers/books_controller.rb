class BooksController < ApplicationController
  def index
    books = Book.includes(:active_borrowing).order(:id)

    render json: books.map { |book| book_json(book) }
  end

  def show
    book = Book.includes(:active_borrowing, borrowings: :reader).find(params[:id])

    render json: book_json(book).merge(borrowings: borrowings_json(book))
  end

  def create
    book = Book.new(book_params)

    if book.save
      render json: book_json(book), status: :created, location: book
    else
      render json: { errors: book.errors }, status: :unprocessable_content
    end
  end

  def destroy
    book = Book.find(params[:id])

    if book.destroy
      head :no_content
    else
      render json: { errors: book.errors }, status: :unprocessable_content
    end
  end

  private
    def book_params
      params.expect(book: %i[ serial_number title author ])
    end

    def book_json(book)
      book.as_json(only: %i[ id serial_number title author ]).merge(status: book.status)
    end

    def borrowings_json(book)
      book.borrowings.sort_by(&:borrowed_on).reverse.map do |borrowing|
        borrowing.as_json(only: %i[ id borrowed_on due_on returned_on ])
          .merge(reader: borrowing.reader.as_json(only: %i[ id card_number name ]))
      end
    end
end
