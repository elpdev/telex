require "rails_helper"

RSpec.describe "API::V1::Contacts", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  it "supports contact CRUD, search, communications, and the one-file note" do
    post "/api/v1/contacts", params: {
      contact: {
        contact_type: "person",
        name: "Alice Smith",
        company_name: "Acme",
        email_addresses: [
          {email_address: "Alice@Example.com", label: "work", primary_address: true}
        ]
      }
    }, headers: headers

    expect(response).to have_http_status(:created)
    contact_id = JSON.parse(response.body).dig("data", "id")
    expect(JSON.parse(response.body).dig("data", "primary_email_address")).to eq("alice@example.com")

    get "/api/v1/contacts", params: {q: "alice"}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", 0, "id")).to eq(contact_id)

    put "/api/v1/contacts/#{contact_id}/note", params: {
      note: {title: "Alice Dossier", body: "Met at RubyConf."}
    }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "body")).to eq("Met at RubyConf.")

    get "/api/v1/contacts/#{contact_id}/note", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "title")).to eq("Alice Dossier")

    contact = Contact.find(contact_id)
    message = create(:message, inbox: create(:inbox, domain: create(:domain, user: user)), contact: contact, from_address: "alice@example.com")
    create(:contact_communication, contact: contact, user: user, communicable: message, occurred_at: message.received_at, metadata: {"direction" => "inbound"})

    get "/api/v1/contacts/#{contact_id}/communications", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", 0, "communication", "from_address")).to eq("alice@example.com")

    patch "/api/v1/contacts/#{contact_id}", params: {contact: {title: "Founder"}}, headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "title")).to eq("Founder")

    delete "/api/v1/contacts/#{contact_id}", headers: headers
    expect(response).to have_http_status(:no_content)
  end

  it "imports contacts from a vcf file" do
    file = fixture_file_upload("contacts/iphone_export.vcf", "text/vcard")

    post "/api/v1/contacts/import_vcf", params: {file: file}, headers: headers

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body).fetch("data")
    expect(payload).to include("created" => 3, "updated" => 0, "skipped" => 0, "failed" => 0, "success" => true)
    expect(user.contacts.find_by(name: "Jane Doe").phone).to eq("(555) 123-4567")
  end
end
