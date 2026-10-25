class Borrowing < ApplicationRecord
  LOAN_PERIOD = 30.days

  belongs_to :reader
  belongs_to :book

  attribute :borrowed_on, default: -> { Date.current }

  scope :active, -> { where(returned_on: nil) }
  scope :returned, -> { where.not(returned_on: nil) }

  before_validation :set_due_on, if: -> { due_on.blank? && borrowed_on.present? }

  validates :borrowed_on, :due_on, presence: true
  validates :book_id, uniqueness: { conditions: -> { active }, message: "is already borrowed" }, if: :active?
  validates :due_on, comparison: { greater_than: :borrowed_on }, if: :borrowed_on
  validates :returned_on, comparison: { greater_than_or_equal_to: :borrowed_on }, allow_nil: true, if: :borrowed_on

  def active?
    returned_on.nil?
  end

  private
    def set_due_on
      self.due_on = borrowed_on + LOAN_PERIOD
    end
end
