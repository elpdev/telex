class API::V1::ContactNotesController < API::V1::BaseController
  before_action :set_contact

  def show
    render_data(API::V1::Serializers.contact_note(@contact, Contacts::NoteFile.read(@contact)))
  end

  def update
    note = Contacts::NoteFile.write!(
      @contact,
      title: note_params[:title],
      body: note_params[:body]
    )

    render_data(API::V1::Serializers.contact_note(@contact, note))
  end

  private

  def set_contact
    @contact = current_user.contacts.includes(:note_file).find(params[:contact_id])
  end

  def note_params
    params.require(:note).permit(:title, :body)
  end
end
