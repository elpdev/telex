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

  it "updates contact fields from note frontmatter and preserves the editable document" do
    contact = create(:contact, user: user, name: "Alice")
    body = <<~MARKDOWN
      ---
      note_title: Alice Dossier
      contact_type: person
      name: Alice Smith
      company_name: Acme
      title: Founder
      phone: "+1 555 123 4567"
      website: "https://example.com"
      ---
      Met at RubyConf.
    MARKDOWN

    put "/api/v1/contacts/#{contact.id}/note", params: {
      note: {title: "Ignored Title", body: body}
    }, headers: headers

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body).fetch("data")
    expect(payload["title"]).to eq("Alice Dossier")
    expect(payload["body"]).to eq(body)

    contact.reload
    expect(contact).to have_attributes(
      contact_type: "person",
      name: "Alice Smith",
      company_name: "Acme",
      title: "Founder",
      phone: "+1 555 123 4567",
      website: "https://example.com"
    )
  end

  it "keeps plain note bodies working without frontmatter" do
    contact = create(:contact, user: user, name: "Plain Contact", title: "Existing")

    put "/api/v1/contacts/#{contact.id}/note", params: {
      note: {title: "Plain Note", body: "Just notes."}
    }, headers: headers

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body).fetch("data")
    expect(payload["title"]).to eq("Plain Note")
    expect(payload["body"]).to eq("Just notes.")
    expect(contact.reload.title).to eq("Existing")
  end

  it "rejects invalid contact types in note frontmatter" do
    contact = create(:contact, user: user)
    body = <<~MARKDOWN
      ---
      contact_type: robot
      ---
      Invalid type.
    MARKDOWN

    put "/api/v1/contacts/#{contact.id}/note", params: {
      note: {title: "Invalid", body: body}
    }, headers: headers

    expect(response).to have_http_status(:unprocessable_content)
    payload = JSON.parse(response.body)
    expect(payload["details"]["contact_type"]).to include("Contact type must be person or business")
    expect(contact.reload.note_file).to be_nil
  end

  it "reads and edits contacts without an existing note" do
    contact = create(:contact, user: user, name: "No Note")

    get "/api/v1/contacts/#{contact.id}/note", headers: headers

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body).fetch("data")
    expect(payload).to include("title" => "No Note", "body" => "")

    put "/api/v1/contacts/#{contact.id}/note", params: {
      note: {title: "Created Note", body: "Now editable."}
    }, headers: headers

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("data", "body")).to eq("Now editable.")
  end
end
