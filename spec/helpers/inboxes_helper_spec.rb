require "rails_helper"

RSpec.describe InboxesHelper, type: :helper do
  describe "#command_palette_search_href" do
    it "preserves inbox scope while clearing transient browser state" do
      scoped_params = ActionController::Parameters.new(
        mailbox: "junk",
        inbox_id: "12",
        domain_id: "4",
        label_id: "9",
        message_id: "55",
        page: "3",
        attachment_id: "88",
        q: {
          query: "old query",
          sender: "alice@example.com",
          recipient: "team@example.com"
        }
      )

      allow(helper).to receive(:controller_name).and_return("inboxes")
      allow(helper).to receive(:action_name).and_return("index")
      allow(helper).to receive(:params).and_return(scoped_params)

      href = helper.command_palette_search_href
      query = Rack::Utils.parse_nested_query(URI.parse(href).query)

      expect(query).to eq({
        "mailbox" => "junk",
        "inbox_id" => "12",
        "domain_id" => "4",
        "label_id" => "9",
        "q" => {
          "query" => InboxesHelper::COMMAND_PALETTE_QUERY_PLACEHOLDER,
          "sender" => "alice@example.com",
          "recipient" => "team@example.com"
        }
      })
    end

    it "falls back to a global inbox search outside the inbox browser" do
      allow(helper).to receive(:controller_name).and_return("profiles")
      allow(helper).to receive(:action_name).and_return("show")
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new)

      href = helper.command_palette_search_href
      query = Rack::Utils.parse_nested_query(URI.parse(href).query)

      expect(query).to eq({
        "mailbox" => "inbox",
        "q" => {"query" => InboxesHelper::COMMAND_PALETTE_QUERY_PLACEHOLDER}
      })
    end
  end
end
