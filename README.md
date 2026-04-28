# Telex

A self-hosted, file-first workspace for email, calendar, drive, notes, tasks, and contacts. Built on Rails 8 with a keyboard-first terminal UI and a JWT-secured REST API that agents and humans can drive side by side.

## What It Is

Telex is the server component of a personal workspace you run on your own hardware. It receives email across multiple domains, organizes messages into threaded conversations, and gives you six surfaces — inbox, calendar, drive, notes, tasks, and contacts — all backed by real files in your own object store.

Data is stored in open formats: `.eml` for email, `.ics` for events, `.md` for notes, `.json` for tasks, `.vcard` for contacts, and whatever you upload for drive. You can grep, mount, sync, and edit them with the tools you already use.

The web UI is built with Hotwire and Tailwind. The human surface is [telex-cli](https://github.com/elpdev/telex-cli), a Go TUI that speaks the same REST API as everything else.

## Stack

- **Ruby 4.0.2**, **Rails 8.1**
- **Database:** SQLite3
- **Queue:** Solid Queue
- **Cache / Cable:** Solid Cache, Solid Cable
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS
- **Auth:** Rails built-in (`has_secure_password`) + JWT for API
- **Testing:** RSpec with FactoryBot and Shoulda Matchers
- **Style:** StandardRB
- **Deploy:** Kamal + Docker (image published to `ghcr.io/elpdev/telex`)

## Getting Started

```bash
bin/setup   # Install deps, prepare database, start server
bin/dev     # Start Rails + Tailwind watcher
```

Visit `http://localhost:3000` and sign in with the default admin account (created during setup) or register a new user.

## Running Tests

```bash
bundle exec rspec              # All tests
bundle exec rspec spec/models  # Specific directory
bundle exec standardrb         # Lint check
bundle exec standardrb --fix   # Auto-fix style
```

## Key Features

### Email
- Manage multiple domains and inboxes
- Inbound messages via Action Mailbox, stored with attachments and rich text bodies
- Threaded conversation tracking linking inbound and outbound messages
- Outbound drafting, queuing, and delivery via configurable SMTP per domain
- Reply, reply-all, forward, archive, trash, junk, star, block sender, labels

### Calendar
- Calendar events extracted from inbox invitations
- Plain `.ics` storage, round-tripping back as email attachments
- Import external ICS feeds

### Drive
- File and folder storage backed by Active Storage (local or S3)
- Root-scoped folders per domain / user

### Notes
- Markdown workspace backed by Drive folders
- Nested folder structure, editable in any editor

### Tasks
- Projects, boards, and cards with full history
- Move cards via API or TUI

### Contacts
- Address book built from real conversation history
- Threaded communications, tags, and searchable metadata

### API
- Full REST API under `/api/v1`
- JWT authentication via `/api/v1/auth/token`
- API key management at `/api_keys`
- Every UI action is available over JSON

### Admin & Operations
- Madmin dashboard at `/madmin` (admin users only)
- Mission Control Jobs at `/jobs` for Solid Queue monitoring
- Flipper feature flags at `/flipper`
- Maintenance tasks dashboard at `/maintenance_tasks`

## Deployment

A production Docker image is published to GitHub Container Registry on every push to `main` and every version tag:

```bash
docker pull ghcr.io/elpdev/telex:latest
```

Kamal configuration lives in `config/deploy.yml`. See the publish workflow in `.github/workflows/publish-ghcr.yml` for details.

## Project Structure

```
app/models/          # Domain models (domains, inboxes, messages, conversations, etc.)
app/controllers/     # Web + API controllers
app/views/           # ERB templates + View Components
app/jobs/            # Solid Queue background jobs
app/mailers/         # Outbound delivery
app/mailboxes/       # Action Mailbox inbound routing
app/clients/         # HTTP API clients
app/services/        # Business logic services
app/components/      # ViewComponent UI pieces
app/serializers/     # API serializers
config/routes.rb     # Route definitions
db/migrate/          # Migrations
spec/                # RSpec test suite
docs/api.md          # API endpoint reference
```

## License

MIT
