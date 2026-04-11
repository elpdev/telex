require "rails_helper"

RSpec.describe EmailTemplate, type: :model do
  describe "validations" do
    it "requires a name" do
      template = build(:email_template, name: nil)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("can't be blank")
    end

    it "enforces unique name per domain" do
      domain = create(:domain)
      create(:email_template, domain: domain, name: "Welcome")
      duplicate = build(:email_template, domain: domain, name: "Welcome")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "allows the same name across different domains" do
      create(:email_template, domain: create(:domain), name: "Welcome")
      sibling = build(:email_template, domain: create(:domain), name: "Welcome")

      expect(sibling).to be_valid
    end
  end
end
