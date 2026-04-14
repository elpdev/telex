class EmailSignaturesController < ApplicationController
  before_action :set_email_signature, only: [:edit, :update, :destroy]

  def index
    @email_signatures = EmailSignature.joins(:domain).where(domains: {user_id: Current.user.id}).includes(:domain).order("domains.name", :name)
  end

  def new
    @email_signature = EmailSignature.new(domain: default_domain)
  end

  def create
    @email_signature = EmailSignature.new(email_signature_params)
    if @email_signature.save
      redirect_to email_signatures_path, notice: "Signature created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @email_signature.update(email_signature_params)
      redirect_to email_signatures_path, notice: "Signature updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @email_signature.destroy
    redirect_to email_signatures_path, notice: "Signature deleted."
  end

  private

  def set_email_signature
    @email_signature = EmailSignature.joins(:domain).where(domains: {user_id: Current.user.id}).find(params[:id])
  end

  def email_signature_params
    params.require(:email_signature).permit(:name, :domain_id, :is_default, :body)
  end

  def default_domain
    Current.user.domains.order(:name).first
  end
end
