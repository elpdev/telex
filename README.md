# Inbox

A Rails application generated with [Boilercode](https://boilercode.io).

## Table of Contents

- [Getting Started](#getting-started)
- [Authentication](#authentication)
- [Admin Dashboard](#admin-dashboard)
- [API](#api)
- [Utilities](#utilities)
- [Development](#development)
- [Deployment](#deployment)
- [Testing](#testing)

## Getting Started

### Requirements

- Ruby 4.0.2+
- SQLite3

### Setup

```bash
bin/setup
```

This installs dependencies, prepares the database, and starts the development server.

### Development

```bash
bin/dev
```

This starts the Rails server and Tailwind CSS watcher.

## Deployment

### GHCR Package

This repository publishes a production image to GitHub Container Registry as `ghcr.io/elpdev/telex`.

The publish workflow lives at `.github/workflows/publish-ghcr.yml` and runs on:

- pushes to `main`
- version tags matching `v*`
- manual runs from the Actions tab

To let your deploy target pull from GHCR, create a GitHub personal access token with package read access and store it as `KAMAL_REGISTRY_PASSWORD` in your deploy secrets.

Example login check:

```bash
echo "$KAMAL_REGISTRY_PASSWORD" | docker login ghcr.io -u elpdev --password-stdin
docker pull ghcr.io/elpdev/telex:latest
```

## Authentication

### User Authentication

This app uses Rails 8's built-in authentication system.

**Default Admin User:**

- Email: `admin@example.com`
- Password: `abc123`

**Creating New Users:**

```ruby
User.create(
  email_address: "user@example.com",
  password: "your-password",
  admin: false
)
```

**Admin Access:**

Admin users have access to protected admin routes. Set `admin: true` on a user to grant admin privileges:

```ruby
user.update(admin: true)
```

## Admin Dashboard

### Admin Panel (Madmin)

The admin panel is available at `/admin` for admin users.

**Features:**

- Auto-generated CRUD interfaces for all models
- Search and filtering capabilities
- Customizable dashboards

**Customizing Admin Resources:**

Admin resources are in `app/madmin/resources/`. To customize a resource:

```ruby
# app/madmin/resources/user_resource.rb
class UserResource < Madmin::Resource
  attribute :id, form: false
  attribute :email_address
  attribute :admin
  attribute :created_at, form: false
end
```

### Job Monitoring (Mission Control)

Monitor and manage background jobs at `/admin/jobs` (or `/jobs` if Madmin is not installed).

**Features:**

- View pending, running, and completed jobs
- Retry failed jobs
- Pause and resume queues
- Real-time job statistics

### Maintenance Tasks

Run and monitor maintenance tasks at `/admin/maintenance_tasks` (or `/maintenance_tasks` if Madmin is not installed).

**Creating a Task:**

```bash
bin/rails generate maintenance_tasks:task update_user_data
```

```ruby
# app/tasks/maintenance/update_user_data_task.rb
module Maintenance
  class UpdateUserDataTask < MaintenanceTasks::Task
    def collection
      User.all
    end

    def process(user)
      user.update!(processed_at: Time.current)
    end
  end
end
```

**Running Tasks:**

Tasks can be run from the web UI or via the command line:

```bash
bin/rails maintenance_tasks:run Maintenance::UpdateUserDataTask
```

### Feature Flags (Flipper)

Manage feature flags at `/admin/flipper` (or `/flipper` if Madmin is not installed).

**Usage in Code:**

```ruby
# Check if a feature is enabled
if Flipper.enabled?(:new_dashboard)
  # show new dashboard
end

# Enable for specific users
Flipper.enable(:beta_feature, current_user)

# Enable for a percentage of users
Flipper.enable_percentage_of_actors(:new_feature, 25)
```

**In Views:**

```erb
<% if Flipper.enabled?(:new_feature, current_user) %>
  <%= render "new_feature" %>
<% end %>
```

## API

### API Endpoints

This app includes a versioned JSON API with JWT authentication.

Full endpoint reference: `docs/api.md`

**Authentication Flow:**

1. Create an API key from the web UI at `/api_keys`
2. Request a JWT token:

```bash
curl -X POST http://localhost:3000/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"client_id": "your_client_id", "secret_key": "your_secret_key"}'
```

3. Use the token in subsequent requests:

```bash
curl http://localhost:3000/api/v1/your_endpoint \
  -H "Authorization: Bearer your_jwt_token"
```

**Creating API Endpoints:**

Add new endpoints in `app/controllers/api/v1/`. Inherit from `Api::V1::BaseController` for automatic JWT authentication:

```ruby
module Api
  module V1
    class UsersController < BaseController
      def index
        render json: User.all
      end
    end
  end
end
```

**Managing API Keys:**

Users can manage their API keys at `/api_keys`. Each key has a client ID and secret key that can be used to obtain JWT tokens.

## Utilities

### Pagination (Pagy)

Pagy is configured for efficient pagination.

**In Controllers:**

```ruby
def index
  @pagy, @users = pagy(User.all)
end
```

**In Views:**

```erb
<%= pagy_nav(@pagy) %>
```

**Customizing:**

```ruby
# Change items per page
@pagy, @users = pagy(User.all, limit: 25)
```

### Column Sorting

Sortable columns are available in index views.

**In Controllers:**

```ruby
def index
  @users = apply_order(User.all)
end
```

**In Views:**

```erb
<th><%= sort_link("Name", :name) %></th>
<th><%= sort_link("Created", :created_at) %></th>
```

**Allowed Columns:**

By default, sorting is allowed on any column. To restrict:

```ruby
def orderable_columns
  %w[name email created_at]
end
```

### Search (Ransack)

Object-based searching using [Ransack](https://github.com/activerecord-hackery/ransack) with a `Searchable` controller concern and a reusable search form partial.

**Controller (using the Searchable concern):**

```ruby
class PostsController < ApplicationController
  def index
    @posts = search(Post)
  end
end
```

The `search` method sets `@q` for the view and returns filtered results. It's available in all controllers via `ApplicationController`.

**Search Form in Views:**

```erb
<%= render "search_form", q: @q, url: posts_path, field: :title_cont, placeholder: "Search posts..." %>
```

The `_search_form` partial renders a styled search input with a search icon. Pass any Ransack predicate as the `field` parameter.

**Common Predicates:**

| Predicate  | Meaning               |
| ---------- | --------------------- |
| `_cont`    | Contains              |
| `_eq`      | Equals                |
| `_gteq`    | Greater than or equal |
| `_lteq`    | Less than or equal    |
| `_start`   | Starts with           |
| `_end`     | Ends with             |
| `_present` | Is not null/blank     |

**Combining with Pagy:**

```ruby
def index
  results = search(Post)
  @pagy, @posts = pagy(results)
end
```

### Notifications (Noticed)

In-app notifications using [Noticed](https://github.com/excid3/noticed). Includes a notification bell in the navbar and a notifications page.

**Creating a Notifier:**

```ruby
# app/notifiers/comment_notifier.rb
class CommentNotifier < Noticed::Event
  deliver_by :action_cable do |config|
    config.channel = "NotificationsChannel"
  end

  notification_methods do
    def message
      "#{params[:user].name} commented on your post."
    end

    def url
      post_path(params[:post])
    end
  end
end
```

**Sending a Notification:**

```ruby
CommentNotifier.with(record: @comment, user: current_user).deliver(@post.author)
```

**In Controllers:**

```ruby
# Mark single notification as read
notification.mark_as_read!

# Get unread notifications
current_user.notifications.unread

# Mark all as read
current_user.notifications.unread.mark_as_read!
```

**Notifications Page:** Visit `/notifications` to see all notifications with read/unread state.

### File Uploads (Active Storage)

Active Storage is configured for file uploads.

**Adding Attachments to Models:**

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  has_many_attached :documents
end
```

**In Forms:**

```erb
<%= form.file_field :avatar %>
<%= form.file_field :documents, multiple: true %>
```

**Displaying Images:**

```erb
<%= image_tag user.avatar if user.avatar.attached? %>
```

**S3 Configuration (if enabled):**

Add your S3 credentials to `config/credentials.yml.enc`:

```yaml
amazon:
  access_key_id: YOUR_ACCESS_KEY
  secret_access_key: YOUR_SECRET_KEY
  region: us-east-1
  bucket: your-bucket-name
```

### Markdown Rendering

Markdown is rendered using [Commonmarker](https://github.com/gjtorikian/commonmarker) (Rust-based, GFM-compliant) with syntax-highlighted code blocks.

**In views (helper):**

```erb
<%= render_markdown("# Hello **world**") %>

<%= render_markdown(@article.body) %>
```

**With ViewComponent (if enabled):**

```erb
<%= render(Markdown::Component.new(text: @article.body)) %>

<%# With a block: %>
<%= render(Markdown::Component.new) do %>
  # Hello **world**
<% end %>

<%# Override theme: %>
<%= render(Markdown::Component.new(text: @content, theme: "InspiredGitHub")) %>
```

**Configuration:** `config/initializers/commonmarker.rb` controls default parse/render options and the syntax highlight theme.

### Rich Text Editor (Action Text)

Action Text provides a rich text editor powered by Trix.

**Adding Rich Text to Models:**

```ruby
class Article < ApplicationRecord
  has_rich_text :content
end
```

**In Forms:**

```erb
<%= form.rich_text_area :content %>
```

**Displaying Content:**

```erb
<%= @article.content %>
```

The content is automatically sanitized and rendered as HTML.

## Development

### Email Previews (Letter Opener)

All emails sent in development are caught and viewable at [/letter_opener](http://localhost:3000/letter_opener) instead of being delivered.

No configuration needed — just send an email from your app and visit `/letter_opener` to see it.

### Outbound Domain Configuration

Outbound delivery is configured per domain in the admin UI at `/admin/domains`.

Each domain can store:

- `outbound_from_name`
- `outbound_from_address`
- `reply_to_address` when reply traffic should go somewhere other than the `From` address
- `smtp_host`
- `smtp_port`
- `smtp_username`
- `smtp_password`
- `smtp_authentication`
- `smtp_enable_starttls_auto`

SMTP credentials are stored with Active Record encryption.

Outbound delivery is only available when the domain is active and the full configuration is present. Incomplete configurations fail validation in the admin UI, and attempts to use an inactive or incomplete domain are logged clearly without exposing SMTP secrets.

Provider setup expectations:

- point the domain at a real SMTP provider and verify the credentials there first
- publish SPF records that authorize that provider to send for the domain
- publish and enable DKIM signing for the same domain
- make sure the configured `outbound_from_address` is allowed by the provider
- set `reply_to_address` only when replies should route somewhere different from the sender address

Outbound send pipeline:

- outbound messages are persisted in `OutboundMessage` records before delivery
- delivery runs in `DeliverOutboundMessageJob`, not inline in controllers
- messages move through `draft`, `queued`, `sending`, `sent`, and `failed` states
- outbound message attachments are delivered through the mailer using Active Storage blobs

## Testing

### Running Tests

```bash
# Run all tests
bin/rspec

# Run specific file
bin/rspec spec/models/user_spec.rb

# Run specific test by line number
bin/rspec spec/models/user_spec.rb:42
```

**Test Helpers:**

FactoryBot is available for creating test data:

```ruby
# Create a user
user = create(:user)

# Build without saving
user = build(:user, email_address: "custom@example.com")
```

Shoulda Matchers are available for concise model tests:

```ruby
RSpec.describe User, type: :model do
  it { should validate_presence_of(:email_address) }
  it { should have_many(:api_keys) }
end
```
