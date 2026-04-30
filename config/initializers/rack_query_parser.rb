# Mailgun posts Action Mailbox MIME payloads as form data. Attachments are MIME/base64
# encoded before Rack parses params, so a 25 MB email can exceed Rack's 4 MB default.
Rack::Utils.default_query_parser = Rack::QueryParser.make_default(
  Rack::Utils.param_depth_limit,
  bytesize_limit: 50.megabytes,
  params_limit: 4096
)
