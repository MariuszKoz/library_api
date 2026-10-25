# Borrowing - data layer

Readers borrow books. A borrowing links one `Book` with one `Reader` and tracks when the book was
borrowed, when it is due back (30 days later) and when it was actually returned.

## Models

### `Reader` (`readers`)

| Column        | Type   | Rules                                                              |
|---------------|--------|--------------------------------------------------------------------|
| `card_number` | string | required, exactly 6 digits (`000123` allowed), unique              |
| `name`        | string | required                                                           |
| `email`       | string | required, valid email format, unique (case-insensitive)            |

- `email` is normalized (`strip` + `downcase`) before validation and before queries
  (`Reader.find_by(email: "A@B.PL")` works).
- `has_many :borrowings, dependent: :restrict_with_error` - a reader with borrowings cannot be destroyed.

### `Book` (`books`)

| Column          | Type   | Rules                                          |
|-----------------|--------|------------------------------------------------|
| `serial_number` | string | required, exactly 6 digits, unique             |
| `title`         | string | required                                       |
| `author`        | string | required                                       |

- `has_many :borrowings, dependent: :restrict_with_error` - a book with borrowings cannot be destroyed.

### `Borrowing` (`borrowings`)

| Column        | Type       | Rules                                                        |
|---------------|------------|--------------------------------------------------------------|
| `reader_id`   | references | required, foreign key to `readers`                           |
| `book_id`     | references | required, foreign key to `books`                             |
| `borrowed_on` | date       | required, defaults to `Date.current`                         |
| `due_on`      | date       | required, defaults to `borrowed_on + Borrowing::LOAN_PERIOD` (30 days); must be after `borrowed_on` |
| `returned_on` | date       | `nil` while the book is borrowed; not before `borrowed_on`  |

- A borrowing with `returned_on: nil` is **active** (`Borrowing.active`); otherwise it is returned
  (`Borrowing.returned`).
- A book can have **at most one active borrowing** at a time. A new borrowing of the same book is allowed
  once the previous one has `returned_on` set.

## Database guarantees

The following rules are also enforced by the database, so they hold even when the model is bypassed:

- `NOT NULL` on all required columns.
- Unique indexes: `readers.card_number`, `readers.email`, `books.serial_number`.
- Check constraints: `card_number` and `serial_number` match `^[0-9]{6}$`; `due_on > borrowed_on`;
  `returned_on IS NULL OR returned_on >= borrowed_on`.
- Foreign keys `borrowings.reader_id` and `borrowings.book_id`.
- Partial unique index on `borrowings.book_id WHERE returned_on IS NULL` (one active borrowing per book).

Model-only rules (not enforced by the database): blank strings in `name`, `title`, `author`; email format;
case-insensitive email uniqueness (the unique index is case-sensitive, `normalizes` downcases the email).

Two concurrent borrowings of the same book can both pass the uniqueness validation; the partial index then
raises `ActiveRecord::RecordNotUnique`. `Books::BorrowingsController` rescues it and returns `422`

## Assumptions (to confirm)

- Card and serial numbers are stored as strings so leading zeros are kept. They are entered, not generated.
- Loan dates are `date`, not `datetime`; the time of day is not tracked.
- `due_on` defaults to 30 days after `borrowed_on` but can be set explicitly to another later date.
- `Date.current` uses the application time zone; `config.time_zone` is not set yet (UTC).
- One active borrowing per book: a serial number identifies one physical copy.
- No limit on how many books one reader can borrow at a time.
