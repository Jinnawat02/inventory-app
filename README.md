# inventory-app

Inventory requisition web app: users request items, admins approve, reject, and fulfill them. See `docs/requirements.md` for the full spec.

## Requirements

- Ruby 3.3.6
- SQLite3

## Setup

```bash
bin/setup --skip-server
```

Seed an admin and two sample users. Values come from environment variables; nothing is hardcoded:

```bash
SEED_ADMIN_EMAIL=you@example.com \
SEED_ADMIN_PASSWORD=choose-a-password \
SEED_USER_PASSWORD=choose-a-password \
bin/rails db:seed
```

The sample users are `somchai@example.com` and `somying@example.com`.

## Development

```bash
bin/dev                   # Rails server + Tailwind watcher at http://localhost:3000
bin/rails test
bin/rubocop
```

## Email

Order notifications are sent with `deliver_later` through Solid Queue. In development nothing is delivered; check the log or the previews at http://localhost:3000/rails/mailers.

Production reads all mail settings from environment variables:

| Variable | Purpose |
|---|---|
| `SMTP_ADDRESS` | SMTP server host |
| `SMTP_PORT` | SMTP port (defaults to 587) |
| `SMTP_USERNAME` | SMTP user |
| `SMTP_PASSWORD` | SMTP password |
| `MAILER_FROM` | Sender address (sending fails if unset) |
| `APP_HOST` | Host used for links in emails |
