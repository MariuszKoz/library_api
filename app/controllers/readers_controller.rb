class ReadersController < ApplicationController
  def create
    reader = Reader.new(reader_params)

    if reader.save
      render json: reader.as_json(only: %i[ id card_number name email ]), status: :created
    else
      render json: { errors: reader.errors }, status: :unprocessable_content
    end
  end

  private
    def reader_params
      params.expect(reader: %i[ card_number name email ])
    end
end
