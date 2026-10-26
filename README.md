# Library API

JSON API for a small library: books, readers, borrowing and returning books, and email reminders about due
dates.

Ruby 3.4.7, Rails 8.1, PostgreSQL 17, Solid Queue for background jobs.

## Running locally

```bash
docker compose up -d --build
curl -i localhost:3000/up    # 200 when the app is up
```

More about the setup (ports, databases, env variables): [docs/development/docker_compose.md](docs/development/docker_compose.md).

### Tests

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
```

## API

| Method   | Path                        | Description                                  |
|----------|-----------------------------|----------------------------------------------|
| `GET`    | `/books`                    | list books with status (available/borrowed)  |
| `GET`    | `/books/:id`                | book details with borrowing history          |
| `POST`   | `/books`                    | add a book                                   |
| `DELETE` | `/books/:id`                | remove a book (only if never borrowed)       |
| `POST`   | `/readers`                  | add a reader                                 |
| `POST`   | `/books/:book_id/borrowing` | lend a book to a reader (by card number)     |
| `POST`   | `/books/:book_id/return`    | return a borrowed book                       |

A book is lent for 30 days. Serial numbers and card numbers have exactly 6 digits.

`jq` is optional, it only pretty-prints JSON.

Details (request/response examples, status codes): [books API](docs/features/books_api.md),
[borrowing API](docs/features/borrowing_api.md), [data model](docs/features/borrowing.md).

### Books

```bash
# Add a book
curl -s -X POST localhost:3000/books -H "Content-Type: application/json" \
  -d '{ "book": { "serial_number": "000777", "title": "Lalka", "author": "Boleslaw Prus" } }' | jq

# List books
curl -s localhost:3000/books | jq

# Show book 1 with its borrowing history
curl -s localhost:3000/books/1 | jq
```

### Readers

```bash
# Add a reader
curl -s -X POST localhost:3000/readers -H "Content-Type: application/json" \
  -d '{ "reader": { "card_number": "100001", "name": "Jan Kowalski", "email": "jan@example.com" } }' | jq
```

### Borrowings

```bash
# Lend book 1 to the reader with card number 100001
curl -s -X POST localhost:3000/books/1/borrowing -H "Content-Type: application/json" \
  -d '{ "card_number": "100001" }' | jq

# Return book 1
curl -s -X POST localhost:3000/books/1/return | jq
```

### Removing a book

Only a book that was never borrowed can be removed (otherwise `422`).

```bash
curl -si -X DELETE localhost:3000/books/1
```

## Reminders

Every day at 8am (UTC) `BorrowingRemindersJob` emails readers whose book is due in 3 days or today. In
development emails are saved to `tmp/mails/` instead of being sent.

```bash
# Run the reminders now
docker compose exec web bin/rails runner "BorrowingRemindersJob.perform_later"

# Run them for a given day
docker compose exec web bin/rails runner "BorrowingRemindersJob.perform_later(Date.new(2026, 11, 21))"

# Check sent emails
ls tmp/mails/
```

Email previews: http://localhost:3000/rails/mailers. More: [docs/features/borrowing_reminders.md](docs/features/borrowing_reminders.md).
