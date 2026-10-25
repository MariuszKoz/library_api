class Book < ApplicationRecord
  has_many :borrowings, dependent: :restrict_with_error
  has_one :active_borrowing, -> { active }, class_name: "Borrowing"

  validates :serial_number, presence: true, uniqueness: true, format: { with: /\A\d{6}\z/ }
  validates :title, :author, presence: true

  def status
    active_borrowing ? "borrowed" : "available"
  end
end
