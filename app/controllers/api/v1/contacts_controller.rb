class API::V1::ContactsController < API::V1::BaseController
  before_action :set_contact, only: [:show, :update, :destroy, :communications]

  def index
    scope = current_user.contacts.includes(:email_addresses, :note_file).ordered
    scope = scope.where(contact_type: params[:contact_type]) if params[:contact_type].present? && Contact.contact_types.key?(params[:contact_type])
    scope = apply_query(scope)
    scope = apply_contact_updated_since(scope)
    scope = apply_sort(scope, allowed: %w[created_at updated_at name contact_type], default: :name)

    records, meta = paginate(scope.distinct)
    render_data(records.map { |contact| API::V1::Serializers.contact(contact) }, meta: meta)
  end

  def show
    render_data(API::V1::Serializers.contact(@contact, include_note: truthy_param?(params[:include_note])))
  end

  def create
    contact = current_user.contacts.new(contact_params)

    Contact.transaction do
      contact.save!
      sync_email_addresses!(contact) if email_addresses_param_present?
    end

    render_data(API::V1::Serializers.contact(contact.reload), status: :created)
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  def update
    Contact.transaction do
      @contact.update!(contact_params)
      sync_email_addresses!(@contact) if email_addresses_param_present?
    end

    render_data(API::V1::Serializers.contact(@contact.reload))
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  def destroy
    @contact.destroy!
    head :no_content
  end

  def communications
    scope = @contact.contact_communications.includes(:communicable).order(occurred_at: :desc, id: :desc)
    records, meta = paginate(scope)
    render_data(records.map { |communication| API::V1::Serializers.contact_communication(communication) }, meta: meta)
  end

  private

  def set_contact
    @contact = current_user.contacts.includes(:email_addresses, :note_file).find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:contact_type, :name, :company_name, :title, :phone, :website, metadata: {})
  end

  def email_address_params
    params.require(:contact).permit(email_addresses: [:email_address, :label, :primary_address]).fetch(:email_addresses, [])
  end

  def email_addresses_param_present?
    params[:contact].respond_to?(:key?) && params[:contact].key?(:email_addresses)
  end

  def sync_email_addresses!(contact)
    existing_by_email = contact.email_addresses.index_by(&:email_address)
    incoming = email_address_params.map do |attributes|
      attributes.to_h.symbolize_keys.tap do |attrs|
        attrs[:email_address] = ContactEmailAddress.normalize_email(attrs[:email_address])
      end
    end.reject { |attrs| attrs[:email_address].blank? }

    incoming_emails = incoming.map { |attrs| attrs[:email_address] }
    contact.email_addresses.where.not(email_address: incoming_emails).destroy_all

    incoming.each_with_index do |attributes, index|
      email = existing_by_email[attributes[:email_address]] || contact.email_addresses.new(user: current_user, email_address: attributes[:email_address])
      email.assign_attributes(
        user: current_user,
        label: attributes[:label],
        primary_address: truthy_param?(attributes.fetch(:primary_address, index.zero?))
      )
      email.save!
    end
  end

  def apply_query(scope)
    query = params[:q].to_s.strip.downcase
    return scope if query.blank?

    like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    scope.left_outer_joins(:email_addresses).where(
      "LOWER(COALESCE(contacts.name, '')) LIKE :query OR LOWER(COALESCE(contacts.company_name, '')) LIKE :query OR contact_email_addresses.email_address LIKE :query",
      query: like
    )
  end

  def apply_contact_updated_since(scope)
    return scope if params[:updated_since].blank?

    timestamp = parse_timestamp_param(params[:updated_since])
    scope.where(
      "contacts.updated_at >= :timestamp OR EXISTS (SELECT 1 FROM contact_email_addresses WHERE contact_email_addresses.contact_id = contacts.id AND contact_email_addresses.updated_at >= :timestamp) OR EXISTS (SELECT 1 FROM stored_files WHERE stored_files.id = contacts.note_file_id AND stored_files.updated_at >= :timestamp)",
      timestamp: timestamp
    )
  end
end
