# Borrowing reminders

A daily background job emails readers about books that are due back soon.

Related code: `BorrowingRemindersJob`, `BorrowingMailer`, `BorrowingMailerPreview`
(`spec/mailers/previews/`), `Borrowing`, `config/recurring.yml`.

## Schedule

`BorrowingRemindersJob` runs **every day at 8am** (Solid Queue recurring task `borrowing_reminders`, in
`development` and `production`). The time is in UTC, because `config.time_zone` is not set.

For each **active** borrowing (`returned_on: nil`) it enqueues one email:

| Condition                     | Email                     | Subject                                         |
|-------------------------------|---------------------------|-------------------------------------------------|
| `due_on` = today + 3 days     | `BorrowingMailer#due_soon`  | `Reminder: "<title>" is due on <due_on>`        |
| `due_on` = today              | `BorrowingMailer#due_today` | `Today is the last day to return "<title>"`     |

- Returned borrowings and other due dates are skipped.
- Each email is sent by its own `ActionMailer::MailDeliveryJob` (`deliver_later`)
- `perform(date)` accepts a date (default `Date.current`)
- Emails go to `Reader#email`, from `MAILER_FROM` (default `library@example.com`). Each has a text and an
  HTML part with the reader's name, the book's title, author, serial number and the due date.

## Previewing and checking emails (development)

- Previews: http://localhost:3000/rails/mailers (built in memory, no data needed).
- Delivery method `:file`: sent emails are written to `tmp/mails/<recipient>`; the full payload is also in the
  log (`docker compose logs web`).
- Run the job now instead of waiting for 8am:

```bash
docker compose exec web bin/rails runner "BorrowingRemindersJob.perform_later"
```

## Known limitations

- Running the job twice on the same day sends the reminders twice; sent reminders are not stored.
- Production has no SMTP settings yet (`config.action_mailer.smtp_settings` in
  `config/environments/production.rb`), so emails cannot be delivered there until it is configured.
