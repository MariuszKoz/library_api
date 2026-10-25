# Borrowing API

JSON endpoints for creating readers, lending books and registering returns.

## Endpoints

| Method | Path                        | Success                  | Errors              |
|--------|-----------------------------|--------------------------|---------------------|
| `POST` | `/readers`                  | `201` created reader     | `400`, `422`        |
| `POST` | `/books/:book_id/borrowing` | `201` created borrowing  | `400`, `404`, `422` |
| `POST` | `/books/:book_id/return`    | `200` closed borrowing   | `404`, `422`        |

### `POST /readers`

```json
{ "reader": { "card_number": "000123", "name": "Jan Kowalski", "email": "jan@example.com" } }
```

- `201` returns `id`, `card_number`, `name`, `email`.
- `422` returns `{ "errors": { "<attribute>": ["<message>"] } }`.
- `400` when no reader attributes are sent.

### `POST /books/:book_id/borrowing`

```json
{ "card_number": "000123" }
```

Lends the book to the reader with this card number. `borrowed_on` is today, `due_on` is 30 days later
(`Borrowing::LOAN_PERIOD`).

```json
{
  "id": 8, "borrowed_on": "2026-10-25", "due_on": "2026-11-24", "returned_on": null,
  "book": { "id": 3, "serial_number": "200003", "title": "The Hobbit" },
  "reader": { "id": 1, "card_number": "000123", "name": "Jan Kowalski" }
}
```

- `404` with `{ "error": "Reader not found" }` when no reader has this card number - no borrowing is created.
- `404` with `{ "error": "Not found" }` for an unknown book.
- `422` with `{ "errors": { "book_id": ["is already borrowed"] } }` when the book has an active borrowing,
  also when two requests race and the partial unique index rejects the second one.
- `400` when `card_number` is missing or blank.
- Send `card_number` as a string: a JSON number `123` does not match `"000123"`.

### `POST /books/:book_id/return`

Closes the book's active borrowing (`returned_on` = today). The book becomes `"available"`.

- `200` returns the closed borrowing (same shape as above).
- `422` with `{ "error": "Book is not borrowed" }` when the book has no active borrowing.
- `404` for an unknown book.

## Usage examples

```bash
# Create a reader
curl -i -X POST http://localhost:3000/readers \
  -H "Content-Type: application/json" \
  -d '{"reader": {"card_number": "000123", "name": "Jan Kowalski", "email": "jan@example.com"}}'

# Lend book 1 to the reader
curl -i -X POST http://localhost:3000/books/1/borrowing \
  -H "Content-Type: application/json" \
  -d '{"card_number": "000123"}'

# Return book 1
curl -i -X POST http://localhost:3000/books/1/return
```
