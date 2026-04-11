# AGENTS.md

This file provides guidance for agents working in this repository.

## Project Overview

Inbox is a Rails application for receiving, organizing, and replying to email across managed domains and inboxes.

The core product centers on:

- domains with inbound and outbound email configuration
- inboxes that map email addresses to inbound processing pipelines
- inbound messages stored with attachments, rich text bodies, and metadata
- conversation tracking that links inbound and outbound messages into a shared timeline
- outbound drafting, queuing, and delivery flows for replies, reply-all, and forwarding
- a web UI plus a JWT-protected JSON API for inbox, conversation, message, notification, and delivery operations

The app started from [Boilercode](https://boilercode.io), but the active domain model is an email inbox and conversation management platform.

## Stack

- Ruby 4.0.1, Rails 8
- Database: SQLite3
- Queue: Solid Queue
- Frontend: Hotwire (Turbo + Stimulus), Tailwind CSS
- Authentication: Rails built-in (User model)
- Testing: RSpec with FactoryBot, Shoulda Matchers
- Linter: StandardRB

## Common Commands

```bash
bin/setup              # Install dependencies, prepare database, start server
bin/dev                # Start development server (Rails + Tailwind watcher)
bundle exec rspec    # Run all tests
bundle exec rspec spec/models  # Run specific directory
bundle exec rspec spec/models/user_spec.rb:42  # Run specific test
bundle exec standardrb       # Check Ruby style
bundle exec standardrb --fix # Auto-fix style issues
bin/rails console      # Start Rails console
bin/rails generate     # Run Rails generators
```

## Architecture

### Authentication

Uses Rails 8 built-in authentication (User model with `has_secure_password`).

- `app/controllers/sessions_controller.rb` - Login/logout
- `app/controllers/registrations_controller.rb` - Sign up
- `app/controllers/concerns/authentication.rb` - Auth concern (included in ApplicationController)
- `app/models/current.rb` - `Current.user` thread-local accessor

Access the current user via `Current.user`. Controllers require authentication by default; opt out with `allow_unauthenticated_access`.

### Admin Panel

Madmin provides an auto-generated admin dashboard at `/madmin`. Admin access requires `user.admin?`.

- Dashboard resources: `app/madmin/resources/`
- Customize fields, scopes, and actions by overriding resource classes

### API

RESTful JSON API under `app/controllers/api/v1/`, routed at `/api/v1/`. Uses JWT token authentication via `JwtService`.

- `app/controllers/api/base_controller.rb` - API base controller
- `app/services/jwt_service.rb` - Token encode/decode

### Background Jobs

Uses Solid Queue (database-backed). Jobs go in `app/jobs/`.

- Queue configuration: `config/queue.yml`
- Create jobs: `bin/rails generate job ProcessOrder`- Dashboard: Mission Control Jobs at `/jobs` (admin-only)

### Notifications

Uses Noticed for in-app notifications. Notifiers live in `app/notifiers/`.

- Generate: `bin/rails generate noticed:notifier CommentNotifier`
- Deliver: `CommentNotifier.with(record: @comment).deliver(user)`
- Query: `user.notifications`

### Feature Flags

Uses Flipper for runtime feature toggling. Dashboard at `/flipper` (admin-only).

- Check: `Flipper.enabled?(:new_feature)`
- Enable: `Flipper.enable(:new_feature)` or `Flipper.enable_actor(:new_feature, user)`

### Search

Uses Ransack for model searching and filtering.

- Add `ransackable_attributes` and `ransackable_associations` to models
- Controller: `Model.ransack(params[:q]).result`
- Views: `search_form_for @q`

### Markdown Rendering

Uses Commonmarker (GFM-compliant) with syntax highlighting. Helper: `render_markdown(text)`.

- Configuration: `config/initializers/commonmarker.rb`
- Helper: `app/helpers/markdown_helper.rb`
- Component: `Markdown::Component` in `app/components/markdown/`

### Rich Text

Uses Action Text. Add `has_rich_text :body` to models, use `form.rich_text_area :body` in forms.

### File Storage

Uses Active Storage. Configuration: `config/storage.yml`.

### HTTP Client

Uses HTTParty with an `ApplicationClient` base class in `app/clients/`.

### Progressive Web App

PWA support with service worker and web manifest.

- Manifest: `app/views/pwa/manifest.json.erb`
- Service worker: `app/views/pwa/service-worker.js`

### Maintenance Tasks

Uses MaintenanceTasks for data operations. Dashboard at `/maintenance_tasks` (admin-only).

- Generate: `bin/rails generate maintenance_tasks:task BackfillUserNames`
- Tasks live in `app/tasks/maintenance/`

### View Components

Uses ViewComponent for encapsulated, testable view components in `app/components/`.

- Generate: `bin/rails generate component Button`
- Render: `render(ButtonComponent.new(label: "Click"))`

## Project Structure

```
app/models/          # ActiveRecord models
app/controllers/     # Request handlers
app/views/           # ERB templates
app/jobs/            # Background jobs
app/mailers/         # Email delivery
app/clients/         # HTTP API clients
app/notifiers/       # Noticed notification classes
app/components/      # ViewComponent classes
app/tasks/           # Maintenance tasks
config/routes.rb     # Route definitions
db/migrate/          # Database migrations
spec/                # RSpec tests
```

## Conventions

- Follow Rails conventions for file naming and directory structure
- Generate migrations with `bin/rails generate migration AddFieldToTable field:type`
- Run `bundle exec standardrb --fix` before committing
- Write request specs for controllers, model specs for business logic
- Use FactoryBot factories (in `spec/factories/`) instead of fixtures
