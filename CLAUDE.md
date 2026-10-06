# CLAUDE.md

Inventory requisition web app: users request items, admins approve, reject, and fulfill. Rails 8.1.4, Ruby 3.3, SQLite.
Full spec: `docs/requirements.md` (English, source of truth) — read it before starting any task.
Do not read or edit `docs/requirements.th.md`; it is a Thai translation for humans and is maintained manually.

## Commands

```bash
bin/setup                 # install gems, prepare DB
bin/rails db:migrate
bin/rails db:seed         # needs SEED_ADMIN_EMAIL, SEED_ADMIN_PASSWORD, SEED_USER_PASSWORD
bin/rails test            # must pass before push
bin/rubocop               # must pass before push
bin/rubocop -a
bin/rails server          # http://localhost:3000, mailer previews at /rails/mailers
```

Bootstrap (Phase 1 only, if the app does not exist yet):
`rails _8.1.4_ new . --name=inventory_app --database=sqlite3 --skip-jbuilder`
Keep the existing README content; merge rather than discard it.

## Workflow

- Work on one Phase from `docs/requirements.md` per session. Do not start the next Phase unless asked.
- Before writing code, state a short plan (files to touch, migrations, tests).
- Tick the acceptance criteria checkboxes in `docs/requirements.md` that the change completes.
- Finish by summarizing what changed, how to verify it, and any open questions.

## Code Style

- Do not write comments in code. No inline comments, block comments, or doc comments in Ruby, ERB, JavaScript, CSS, migrations, or tests. Express intent through clear names, small methods, and tests instead.
- Do not leave commented-out code or TODO notes. Put open questions in the end-of-session summary.
- Explanations belong in the session summary or commit messages, not in source files.

## Conventions

- Follow Rails defaults: RESTful resources, thin controllers, validations and domain logic in models.
- Use strong parameters; never `permit!`.
- Authentication: the Rails 8 authentication generator. Authorization: plain `before_action` filters (`require_admin`), no gems.
- Always scope user-facing queries to `Current.user` (e.g. `Current.user.orders.find(params[:id])`) so other users' records return 404.
- Order status changes go through model methods (`approve!`, `reject!`, `fulfill!`, `cancel!`) that enforce the transition table in the spec. Never update `status` directly from controllers.
- Stock deduction on approval runs in one `ActiveRecord::Base.transaction` with `lock` on the affected items.
- Send emails with `deliver_later`, triggered after commit.
- Add DB-level constraints alongside model validations (`null: false`, unique indexes, defaults, foreign keys).
- UI and email text in Thai; identifiers and commit messages in English.
- Hotwire + importmap only. No Node.js, no new gems without explaining why in the summary.

## Testing

- Minitest with fixtures in `test/fixtures`.
- Every model change needs model tests; every controller action needs integration tests, including authorization (user vs admin vs other user's records).
- Mailers: unit tests plus `assert_enqueued_email_with` / `assert_no_enqueued_emails` in integration tests.
- Do not write system tests (no browser in the cloud environment).

## Security (mandatory)

- Never hardcode secrets, credentials, API keys, SMTP settings, or passwords in code, seeds, fixtures, tests, or docs. Use `ENV.fetch` or Rails credentials. Fixtures may use obviously fake test passwords only.
- Never commit `config/master.key` or `config/credentials/*.key`. Confirm they are in `.gitignore`. In the cloud environment the key comes from `RAILS_MASTER_KEY`.
- If you find a hardcoded secret anywhere in the repo, stop and report it: the user must purge it from git history and rotate it.
- Keep `config/initializers/filter_parameter_logging.rb` intact.

## Git

- Small, focused commits with imperative messages, e.g. `Add approve transition to orders`.
- Never force-push or rewrite history on `main`.