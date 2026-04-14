class DomainsController < ApplicationController
  before_action :set_domain, only: [:show, :edit, :update, :destroy]

  def index
    @domains = Current.user.domains.includes(:inboxes).order(:name)
  end

  def show
    @inboxes = @domain.inboxes.order(:address)
  end

  def new
    @domain = Domain.new(active: true, use_from_address_for_reply_to: true, smtp_enable_starttls_auto: true)
  end

  def create
    @domain = Current.user.domains.new(domain_params)

    if @domain.save
      redirect_to domain_path(@domain), notice: "Domain created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @domain.update(domain_params)
      redirect_to domain_path(@domain), notice: "Domain updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @domain.destroy
    redirect_to domains_path, notice: "Domain deleted."
  end

  private

  def set_domain
    @domain = Current.user.domains.find(params[:id])
  end

  def domain_params
    params.require(:domain).permit(
      :name,
      :active,
      :folder_id,
      :outbound_from_name,
      :outbound_from_address,
      :use_from_address_for_reply_to,
      :reply_to_address,
      :smtp_host,
      :smtp_port,
      :smtp_authentication,
      :smtp_enable_starttls_auto,
      :smtp_username,
      :smtp_password
    )
  end
end
