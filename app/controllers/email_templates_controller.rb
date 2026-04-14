class EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: [:edit, :update, :destroy]

  def index
    @email_templates = EmailTemplate.joins(:domain).where(domains: {user_id: Current.user.id}).includes(:domain).order("domains.name", :name)
  end

  def new
    @email_template = EmailTemplate.new(domain: default_domain)
  end

  def create
    @email_template = EmailTemplate.new(email_template_params)
    if @email_template.save
      redirect_to email_templates_path, notice: "Template created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @email_template.update(email_template_params)
      redirect_to email_templates_path, notice: "Template updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @email_template.destroy
    redirect_to email_templates_path, notice: "Template deleted."
  end

  private

  def set_email_template
    @email_template = EmailTemplate.joins(:domain).where(domains: {user_id: Current.user.id}).find(params[:id])
  end

  def email_template_params
    params.require(:email_template).permit(:name, :domain_id, :subject, :body)
  end

  def default_domain
    Current.user.domains.order(:name).first
  end
end
