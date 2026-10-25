module BorrowingRendering
  private
    def borrowing_json(borrowing)
      borrowing.as_json(only: %i[ id borrowed_on due_on returned_on ]).merge(
        book: borrowing.book.as_json(only: %i[ id serial_number title ]),
        reader: borrowing.reader.as_json(only: %i[ id card_number name ])
      )
    end
end
