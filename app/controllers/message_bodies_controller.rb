class MessageBodiesController < ApplicationController
  def show
    @message = Message.joins(inbox: :domain).where(domains: {user_id: Current.user.id}).find(params[:id])

    render html: iframe_document.html_safe, layout: false
  end

  private

  def iframe_document
    html = rewrite_inline_asset_urls(@message.raw_html_body)
    return plain_text_document if html.blank?

    if html.match?(%r{<html|<body|<head}i)
      inject_iframe_head(html)
    else
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <base target="_blank">
          </head>
          <body>#{html}</body>
        </html>
      HTML
    end
  end

  def inject_iframe_head(html)
    head_markup = <<~HTML.squish
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width,initial-scale=1">
      <base target="_blank">
      <script>
        (() => {
          const publishHeight = () => {
            const body = document.body
            const doc = document.documentElement
            const height = Math.max(
              body ? body.scrollHeight : 0,
              doc ? doc.scrollHeight : 0,
              body ? body.offsetHeight : 0,
              doc ? doc.offsetHeight : 0
            )

            parent.postMessage({ type: "message-body:resize", height: height, messageId: #{@message.id} }, "*")
          }

          window.addEventListener("load", publishHeight)
          window.addEventListener("resize", publishHeight)

          if (window.ResizeObserver) {
            const observer = new ResizeObserver(publishHeight)
            window.addEventListener("load", () => {
              if (document.body) observer.observe(document.body)
            })
          }
        })()
      </script>
    HTML

    return html.sub(/<head([^>]*)>/i, "<head\\1>#{head_markup}") if html.match?(/<head[^>]*>/i)

    if html.match?(/<html[^>]*>/i)
      html.sub(/<html([^>]*)>/i, "<html\\1><head>#{head_markup}</head>")
    else
      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>#{head_markup}</head>
          <body>#{html}</body>
        </html>
      HTML
    end
  end

  def plain_text_document
    <<~HTML
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width,initial-scale=1">
          <style>
            body {
              margin: 0;
              padding: 16px;
              font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
              white-space: pre-wrap;
              word-break: break-word;
              color: #111827;
              background: #ffffff;
            }

            @media (prefers-color-scheme: dark) {
              body {
                color: #f9fafb;
                background: #111827;
              }
            }
          </style>
        </head>
        <body>#{ERB::Util.html_escape(@message.text_body.to_s)}</body>
      </html>
    HTML
  end

  def rewrite_inline_asset_urls(html)
    return if html.blank?

    html.gsub(/(src|href)=(['"])cid:(.+?)\2/i) do
      attribute = Regexp.last_match(1)
      quote = Regexp.last_match(2)
      content_id = Regexp.last_match(3)
      token = @message.inline_asset_token(content_id)

      %(#{attribute}=#{quote}#{inline_asset_message_path(@message, token: token)}#{quote})
    end
  end
end
