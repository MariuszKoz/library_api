# Local development with docker compose

## Files

- `compose.yaml` - services `db` (PostgreSQL 17) and `web` (Rails server on port 3000). The `web` command
  installs gems added to the Gemfile after the image was built, removes a stale `tmp/pids/server.pid`,
  runs `bin/rails db:prepare` and starts the server.
- `Dockerfile.dev` - development image (all gem groups, build tools). The production image is still `Dockerfile`.

`web` connects through `DATABASE_URL=postgres://postgres:postgres@db:5432`. The URL has **no database name** on
purpose: Rails takes the name from `config/database.yml` for the current env, so `development` and `test` use
separate databases. Adding a name to the URL would make tests run against (and wipe) the development database.

Background jobs, cache and cable use in-process / memory adapters in development, so only the primary
database is needed. The `solid_*` databases are production-only.

## Usage

```bash
docker compose up -d --build           # build image, start db + web
curl -i localhost:3000/up              # expect HTTP 200
docker compose logs -f web             # server log

docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate
docker compose run --rm -e RAILS_ENV=test web bin/rails db:prepare test

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

Connect from the host: `psql -h 127.0.0.1 -p 5433 -U postgres library_api_development`.

## Volumes

- `postgres_data` - database files.
- `bundle` - installed gems.
