# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_11_120000) do
  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_keys", force: :cascade do |t|
    t.string "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.datetime "last_used_at"
    t.string "last_used_ip"
    t.string "name", null: false
    t.string "secret_key_digest", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["client_id"], name: "index_api_keys_on_client_id", unique: true
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_message_at", null: false
    t.json "participant_addresses", default: [], null: false
    t.string "subject_key", null: false
    t.datetime "updated_at", null: false
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["subject_key"], name: "index_conversations_on_subject_key"
  end

  create_table "domains", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "outbound_from_address"
    t.string "outbound_from_name"
    t.string "reply_to_address"
    t.string "smtp_authentication"
    t.boolean "smtp_enable_starttls_auto", default: true, null: false
    t.string "smtp_host"
    t.text "smtp_password"
    t.integer "smtp_port"
    t.text "smtp_username"
    t.datetime "updated_at", null: false
    t.boolean "use_from_address_for_reply_to", default: true, null: false
    t.index ["name"], name: "index_domains_on_name", unique: true
  end

  create_table "flipper_features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature_key", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "inboxes", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "domain_id", null: false
    t.json "forwarding_rules", default: [], null: false
    t.string "local_part", null: false
    t.string "pipeline_key", default: "default", null: false
    t.json "pipeline_overrides"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_inboxes_on_active"
    t.index ["address"], name: "index_inboxes_on_address", unique: true
    t.index ["domain_id", "local_part"], name: "index_inboxes_on_domain_id_and_local_part", unique: true
    t.index ["domain_id"], name: "index_inboxes_on_domain_id"
  end

  create_table "maintenance_tasks_runs", force: :cascade do |t|
    t.text "arguments"
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.string "cursor"
    t.datetime "ended_at"
    t.string "error_class"
    t.string "error_message"
    t.string "job_id"
    t.integer "lock_version", default: 0, null: false
    t.text "metadata"
    t.datetime "started_at"
    t.string "status", default: "enqueued", null: false
    t.string "task_name", null: false
    t.bigint "tick_count"
    t.bigint "tick_total"
    t.float "time_running", default: 0.0, null: false
    t.datetime "updated_at", null: false
    t.index ["task_name", "status", "created_at"], name: "index_maintenance_tasks_runs", order: { created_at: :desc }
  end

  create_table "messages", force: :cascade do |t|
    t.json "cc_addresses"
    t.integer "conversation_id"
    t.datetime "created_at", null: false
    t.string "from_address"
    t.string "from_name"
    t.integer "inbound_email_id", null: false
    t.integer "inbox_id", null: false
    t.string "message_id"
    t.json "metadata"
    t.text "processing_error"
    t.datetime "received_at", null: false
    t.text "recipient_text", default: "", null: false
    t.text "search_text", default: "", null: false
    t.integer "status", default: 0, null: false
    t.string "subaddress"
    t.string "subject"
    t.text "text_body"
    t.json "to_addresses"
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["inbound_email_id"], name: "index_messages_on_inbound_email_id"
    t.index ["inbox_id", "inbound_email_id"], name: "index_messages_on_inbox_id_and_inbound_email_id", unique: true
    t.index ["inbox_id"], name: "index_messages_on_inbox_id"
    t.index ["message_id"], name: "index_messages_on_message_id"
    t.index ["received_at"], name: "index_messages_on_received_at"
    t.index ["status"], name: "index_messages_on_status"
    t.index ["subaddress"], name: "index_messages_on_subaddress"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "notifications_count"
    t.json "params"
    t.bigint "record_id"
    t.string "record_type"
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "read_at", precision: nil
    t.bigint "recipient_id", null: false
    t.string "recipient_type", null: false
    t.datetime "seen_at", precision: nil
    t.string "type"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "outbound_messages", force: :cascade do |t|
    t.json "bcc_addresses", default: [], null: false
    t.json "cc_addresses", default: [], null: false
    t.integer "conversation_id"
    t.datetime "created_at", null: false
    t.integer "delivery_attempts", default: 0, null: false
    t.integer "domain_id", null: false
    t.datetime "failed_at"
    t.string "in_reply_to_message_id"
    t.text "last_error"
    t.string "mail_message_id"
    t.json "metadata"
    t.datetime "queued_at"
    t.json "reference_message_ids", default: [], null: false
    t.datetime "sent_at"
    t.integer "source_message_id"
    t.integer "status", default: 0, null: false
    t.string "subject"
    t.json "to_addresses", default: [], null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["conversation_id"], name: "index_outbound_messages_on_conversation_id"
    t.index ["domain_id"], name: "index_outbound_messages_on_domain_id"
    t.index ["in_reply_to_message_id"], name: "index_outbound_messages_on_in_reply_to_message_id"
    t.index ["mail_message_id"], name: "index_outbound_messages_on_mail_message_id"
    t.index ["queued_at"], name: "index_outbound_messages_on_queued_at"
    t.index ["sent_at"], name: "index_outbound_messages_on_sent_at"
    t.index ["source_message_id"], name: "index_outbound_messages_on_source_message_id"
    t.index ["status"], name: "index_outbound_messages_on_status"
    t.index ["user_id", "status", "updated_at"], name: "index_outbound_messages_on_user_id_and_status_and_updated_at"
    t.index ["user_id"], name: "index_outbound_messages_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_keys", "users"
  add_foreign_key "inboxes", "domains"
  add_foreign_key "messages", "action_mailbox_inbound_emails", column: "inbound_email_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "inboxes"
  add_foreign_key "outbound_messages", "conversations"
  add_foreign_key "outbound_messages", "domains"
  add_foreign_key "outbound_messages", "messages", column: "source_message_id"
  add_foreign_key "outbound_messages", "users"
  add_foreign_key "sessions", "users"
end
