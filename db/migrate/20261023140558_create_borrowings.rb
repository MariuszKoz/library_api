class CreateBorrowings < ActiveRecord::Migration[8.1]
  def change
    create_table :borrowings do |t|
      t.references :reader, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.date :borrowed_on, null: false
      t.date :due_on, null: false
      t.date :returned_on

      t.timestamps
    end
    # A book can be borrowed by only one reader at a time
    add_index :borrowings, :book_id, unique: true, where: "returned_on IS NULL",
      name: "index_borrowings_on_book_id_active"
    add_check_constraint :borrowings, "due_on > borrowed_on", name: "borrowings_due_after_borrowed"
    add_check_constraint :borrowings, "returned_on IS NULL OR returned_on >= borrowed_on",
      name: "borrowings_returned_not_before_borrowed"
  end
end
