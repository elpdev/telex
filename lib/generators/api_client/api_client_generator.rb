class ApiClientGenerator < Rails::Generators::NamedBase
  source_root File.expand_path("templates", __dir__)

  class_option :base_url, type: :string, desc: "Base URL for the API"
  class_option :auth, type: :string, enum: %w[bearer basic none], default: "none", desc: "Authentication type (bearer, basic, none)"

  def create_client
    template "client.rb.tt", "app/clients/#{file_name}_client.rb"
  end

  def create_test
    if rspec?
      template "client_spec.rb.tt", "spec/clients/#{file_name}_client_spec.rb"
    else
      template "client_test.rb.tt", "test/clients/#{file_name}_client_test.rb"
    end
  end

  private

  def client_class_name
    "#{class_name}Client"
  end

  def base_url_value
    options[:base_url]
  end

  def auth_type
    options[:auth]
  end

  def credential_key
    file_name.to_sym
  end

  def rspec?
    File.exist?(Rails.root.join("spec"))
  end
end
