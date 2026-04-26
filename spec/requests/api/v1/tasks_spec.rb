require "rails_helper"

RSpec.describe "API::V1::Tasks", type: :request do
  let(:user) { create(:user) }
  let(:headers) { api_headers_for(user) }

  it "creates the task workspace on first access" do
    expect {
      get "/api/v1/tasks/workspace", headers: headers
    }.to change { user.folders.where(parent_id: nil, name: "Tasks").count }.from(0).to(1)

    expect(response).to have_http_status(:ok)
    payload = JSON.parse(response.body).fetch("data")
    expect(payload.dig("root_folder", "name")).to eq("Tasks")
    expect(payload.dig("projects_folder", "name")).to eq("Projects")
    expect(payload.fetch("projects")).to eq([])
  end

  it "creates a project with markdown manifest, board, and cards folder" do
    post "/api/v1/tasks/projects", params: {project: {name: "Website Redesign"}}, headers: headers

    expect(response).to have_http_status(:created)
    payload = JSON.parse(response.body).fetch("data")

    project = user.folders.find(payload.fetch("id"))
    expect(project.name).to eq("Website Redesign")
    expect(project.metadata).to include("app" => "tasks", "role" => "project")
    expect(project.children.find_by!(name: "cards").metadata).to include("role" => "cards")
    expect(payload.dig("manifest", "filename")).to eq("project.md")
    expect(payload.dig("board", "filename")).to eq("board.md")
    expect(user.stored_files.find_by!(folder: project, filename: "board.md").blob.download).to include("## Todo")
  end

  it "creates cards and exposes board columns with linked card records" do
    project_id = create_project!("Website Redesign")

    post "/api/v1/tasks/projects/#{project_id}/cards", params: {
      card: {
        title: "Homepage Copy",
        body: "# Homepage Copy\n\n- [ ] Draft first pass"
      }
    }, headers: headers

    expect(response).to have_http_status(:created)
    card_payload = JSON.parse(response.body).fetch("data")
    expect(card_payload.fetch("filename")).to eq("Homepage Copy.md")
    expect(card_payload.fetch("body")).to include("Draft first pass")

    patch "/api/v1/tasks/projects/#{project_id}/board", params: {
      board: {
        body: <<~MARKDOWN
          # Website Redesign

          ## Todo
          - [[cards/Homepage Copy.md]]

          ## Doing

          ## Done
        MARKDOWN
      }
    }, headers: headers

    expect(response).to have_http_status(:ok)
    board_payload = JSON.parse(response.body).fetch("data")
    expect(board_payload.fetch("columns").first.fetch("name")).to eq("Todo")
    linked_card = board_payload.fetch("columns").first.fetch("cards").first
    expect(linked_card.fetch("missing")).to eq(false)
    expect(linked_card.dig("card", "id")).to eq(card_payload.fetch("id"))

    get "/api/v1/tasks/projects/#{project_id}/cards", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("data").map { |card| card.fetch("id") }).to eq([card_payload.fetch("id")])
  end

  it "scopes projects to the current user" do
    other_project_id = create_project!("Other", headers: api_headers_for(create(:user)))

    get "/api/v1/tasks/projects/#{other_project_id}", headers: headers

    expect(response).to have_http_status(:not_found)
  end

  def create_project!(name, headers: self.headers)
    post "/api/v1/tasks/projects", params: {project: {name: name}}, headers: headers
    JSON.parse(response.body).fetch("data").fetch("id")
  end
end
