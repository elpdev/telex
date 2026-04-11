# API Reference

Base path: `/api/v1`

Authentication uses bearer JWT tokens from `POST /api/v1/auth/token`.

## Authentication

`POST /auth/token`

Request JSON:

```json
{
  "client_id": "your_client_id",
  "secret_key": "your_secret_key"
}
```

## Meta

- `GET /health`
- `GET /capabilities`

## Me

- `GET /me`
- `PATCH /me`

Fields:

- `user[name]`
- `user[email_address]`
- `user[avatar]`
- `remove_avatar`

## Mailboxes

- `GET /mailboxes`

Returns mailbox counts plus labels, inboxes, and domains for client bootstrap.

## API Keys

- `GET /api_keys`
- `POST /api_keys`
- `GET /api_keys/:id`
- `PATCH /api_keys/:id`
- `DELETE /api_keys/:id`

## Labels

- `GET /labels`
- `POST /labels`
- `GET /labels/:id`
- `PATCH /labels/:id`
- `DELETE /labels/:id`

## Sender Policies

- `GET /sender_policies`
- `POST /sender_policies`
- `GET /sender_policies/:id`
- `PATCH /sender_policies/:id`
- `DELETE /sender_policies/:id`

Filters:

- `kind`
- `disposition`

## Domains

- `GET /domains`
- `POST /domains`
- `GET /domains/:id`
- `PATCH /domains/:id`
- `DELETE /domains/:id`
- `GET /domains/:id/outbound_status`
- `POST /domains/:id/validate_outbound`

## Inboxes

- `GET /inboxes`
- `POST /inboxes`
- `GET /inboxes/:id`
- `PATCH /inboxes/:id`
- `DELETE /inboxes/:id`
- `GET /inboxes/:id/pipeline`
- `POST /inboxes/:id/test_forwarding_rules`
- `GET /inboxes/:inbox_id/messages`
- `GET /inboxes/:inbox_id/conversations`

Filters:

- `domain_id`
- `active`
- `pipeline_key`

## Messages

- `GET /messages`
- `GET /messages/:id`
- `GET /messages/:id/body`
- `GET /messages/:message_id/attachments`
- `GET /messages/:message_id/attachments/:id`
- `GET /messages/:message_id/attachments/:id/download`
- `GET /messages/:id/inline_assets/:token`

Filters:

- `inbox_id`
- `conversation_id`
- `mailbox`
- `label_id`
- `q`
- `sender`
- `recipient`
- `status`
- `subaddress`
- `received_from`
- `received_to`

Actions:

- `POST /messages/:id/reply`
- `POST /messages/:id/reply_all`
- `POST /messages/:id/forward`
- `POST /messages/:id/junk`
- `POST /messages/:id/not_junk`
- `POST /messages/:id/archive`
- `POST /messages/:id/restore`
- `POST /messages/:id/trash`
- `POST /messages/:id/mark_read`
- `POST /messages/:id/mark_unread`
- `POST /messages/:id/star`
- `POST /messages/:id/unstar`
- `POST /messages/:id/block_sender`
- `POST /messages/:id/unblock_sender`
- `POST /messages/:id/block_domain`
- `POST /messages/:id/unblock_domain`
- `POST /messages/:id/trust_sender`
- `POST /messages/:id/untrust_sender`
- `PATCH /messages/:id/labels`

## Message Invitations

- `GET /messages/:id/invitation`
- `POST /messages/:id/invitation/sync`
- `PATCH /messages/:id/invitation`

## Conversations

- `GET /conversations`
- `GET /conversations/:id`
- `GET /conversations/:id/timeline`
- `GET /conversations/:conversation_id/messages`
- `POST /conversations/:id/archive`
- `POST /conversations/:id/restore`
- `POST /conversations/:id/trash`
- `PATCH /conversations/:id/labels`

Filters:

- `inbox_id`
- `mailbox`
- `label_id`
- `q`

## Outbound Messages

- `GET /outbound_messages`
- `POST /outbound_messages`
- `GET /outbound_messages/:id`
- `PATCH /outbound_messages/:id`
- `DELETE /outbound_messages/:id`
- `POST /outbound_messages/compose`
- `POST /outbound_messages/:id/insert_template`
- `POST /outbound_messages/:id/send_message`
- `POST /outbound_messages/:id/queue`

Filters:

- `domain_id`
- `conversation_id`
- `source_message_id`
- `status`

Attachments:

- `GET /outbound_messages/:outbound_message_id/attachments`
- `POST /outbound_messages/:outbound_message_id/attachments`
- `GET /outbound_messages/:outbound_message_id/attachments/:id`
- `GET /outbound_messages/:outbound_message_id/attachments/:id/download`
- `DELETE /outbound_messages/:outbound_message_id/attachments/:id`

## Email Templates

- `GET /email_templates`
- `POST /email_templates`
- `GET /email_templates/:id`
- `PATCH /email_templates/:id`
- `DELETE /email_templates/:id`

Filter:

- `domain_id`

## Email Signatures

- `GET /email_signatures`
- `POST /email_signatures`
- `GET /email_signatures/:id`
- `PATCH /email_signatures/:id`
- `DELETE /email_signatures/:id`

Filter:

- `domain_id`

## Calendars

- `GET /calendars`
- `POST /calendars`
- `GET /calendars/:id`
- `PATCH /calendars/:id`
- `DELETE /calendars/:id`
- `POST /calendars/:id/import_ics`

## Calendar Events

- `GET /calendar_events`
- `POST /calendar_events`
- `GET /calendar_events/:id`
- `PATCH /calendar_events/:id`
- `DELETE /calendar_events/:id`
- `GET /calendar_events/:id/messages`

Filters:

- `calendar_id`
- `starts_from`
- `ends_to`
- `status`
- `source`
- `uid`

## Calendar Occurrences

- `GET /calendar_occurrences`

Filters:

- `calendar_id`
- `calendar_ids[]`
- `starts_from`
- `ends_to`

## Notifications

- `GET /notifications`
- `GET /notifications/:id`
- `PATCH /notifications/:id`
- `POST /notifications/mark_all_read`

Filter:

- `unread`

## Pipelines

- `GET /pipelines`
- `GET /pipelines/:key`
