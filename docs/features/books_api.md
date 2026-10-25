# Books API

JSON endpoints for registering, listing, showing and removing books. Built on the data layer described in
[borrowing.md](borrowing.md).

Related code: `BooksController`, `ApplicationController` (404 handling), `Book`, `Borrowing`, `Reader`.

## Endpoints

| Method   | Path         | Success              | Errors                       |
|----------|--------------|----------------------|------------------------------|
| `GET`    | `/books`     | `200` list of books  | -                            |
| `GET`    | `/books/:id` | `200` book + history | `404`                        |
| `POST`   | `/books`     | `201` created book   | `400`, `422`                 |
| `DELETE` | `/books/:id` | `204` no body        | `404`, `422`                 |

### `GET /books`

Returns all books ordered by `id`, each with its current status.

```json
[
  { "id": 1, "serial_number": "200001", "title": "Dune", "author": "Frank Herbert", "status": "borrowed" }
]
```

- `status` is `"borrowed"` when the book has an active borrowing (`returned_on: nil`), otherwise `"available"`
  (`Book#status`).
- The active borrowing is preloaded through `Book#active_borrowing` (`has_one`, scope `Borrowing.active`),
  so the list runs a fixed number of queries regardless of the number of books.
- No pagination yet.

### `GET /books/:id`

Returns the book (same fields as in the list) plus its full borrowing history, newest `borrowed_on` first.

```json
{
  "id": 2, "serial_number": "200002", "title": "Solaris", "author": "Stanislaw Lem", "status": "available",
  "borrowings": [
    {
      "id": 7, "borrowed_on": "2026-09-15", "due_on": "2026-10-15", "returned_on": "2026-10-10",
      "reader": { "id": 1, "card_number": "100001", "name": "Alice Nowak" }
    }
  ]
}
```

- `returned_on` is `null` for the active borrowing.
- The reader's `email` is not exposed.
- Unknown `id` returns `404` with `{ "error": "Not found" }`.

### `POST /books`

```json
{ "book": { "serial_number": "000777", "title": "Lalka", "author": "Boleslaw Prus" } }
```

- Permitted attributes: `serial_number`, `title`, `author`.
- The `book` key is optional for JSON requests: `wrap_parameters` wraps top-level attributes into `book`.
- `201` returns the created book (with `status: "available"`) and a `Location` header.
- `422` returns `{ "errors": { "<attribute>": ["<message>"] } }` for validation errors (format, blank fields,
  duplicate `serial_number`).
- `400` when no book attributes are sent.

### `DELETE /books/:id`

- `204` when the book has no borrowings.
- `422` with `{ "errors": { "base": ["Cannot delete record because dependent borrowings exist"] } }` when the
  book has **any** borrowings, active or returned. Borrowing history is kept, so such a book cannot be removed.
- `404` for an unknown `id`.

## Usage examples

Start the app with `docker compose up -d`.
API listens on `http://localhost:3000`.
`jq` is optional and only pretty-prints.

```bash
# Health check (200 when the app is up)
curl -i http://localhost:3000/up

# Register a book
curl -i -X POST http://localhost:3000/books \
  -H "Content-Type: application/json" \
  -d '{"book": {"serial_number": "000777", "title": "Lalka", "author": "Boleslaw Prus"}}'

# List books
curl -s http://localhost:3000/books | jq

# Show a book with its borrowing history
curl -s http://localhost:3000/books/1 | jq

# Delete a book (204, or 422 when it has borrowings)
curl -i -X DELETE http://localhost:3000/books/1
```

`POST` requires `Content-Type: application/json`; without it the body is not parsed and the API returns `400`
