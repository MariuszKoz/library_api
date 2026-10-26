# Local development with docker compose

## Files

- `compose.yaml` - services `db` (PostgreSQL 17) and `web` (Rails server on port 3000). The `web` command
  installs gems added to the Gemfile after the image was built, removes a stale `tmp/pids/server.pid`,
  runs `bin/rails db:prepare` and starts the server.
- `Dockerfile.dev` - development image (all gem groups, build tools). The production image is still `Dockerfile`.

- Database connection: `DB_HOST`, `DB_USERNAME`, `DB_PASSWORD` (not `DATABASE_URL`, it doesn't reach the `queue`
  database).
- Development databases: `library_api_development` and `library_api_development_queue` (Solid Queue), both
  created by `bin/rails db:prepare`.
- Background jobs run inside the Rails server (`SOLID_QUEUE_IN_PUMA=1`), recurring ones are in
  `config/recurring.yml`.
- Emails are saved to `tmp/mails/` instead of being sent. Previews: http://localhost:3000/rails/mailers.

## Usage

```bash
docker compose up -d --build           # build image, start db + web
curl -i localhost:3000/up              # expect HTTP 200
docker compose logs -f web             # server log

docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate
docker compose run --rm -e RAILS_ENV=test web bash -c "bundle exec rspec"

docker compose down                    # stop, keep data
docker compose down -v                 # stop and DELETE database data and installed gems
```

After changing `Gemfile`, restart `web` (its command installs missing gems) or run
`docker compose exec web bundle install`.

## Configuration (optional environment variables)

| Variable        | Default    | Purpose                                                       |
|-----------------|------------|---------------------------------------------------------------|
| `WEB_HOST_PORT` | `3000`     | Host port for the Rails server                                |
| `DB_HOST_PORT`  | `5433`     | Host port for PostgreSQL (bound to `127.0.0.1` only)          |
| `DB_USERNAME`   | `postgres` | PostgreSQL user                                               |
| `DB_PASSWORD`   | `postgres` | PostgreSQL password (development only)                        |
| `UID` / `GID`   | `1000`     | Container user, should match the host user (`id -u`, `id -g`) |

Connect from the host: `psql -h 127.0.0.1 -p 5433 -U postgres library_api_development`
(`library_api_development_queue` for the job queue).

## Volumes

- `postgres_data` - database files.
- `bundle` - installed gems.
