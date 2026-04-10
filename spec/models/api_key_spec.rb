require "rails_helper"

RSpec.describe APIKey, type: :model do
  describe "associations" do
    it "belongs to a user" do
      association = described_class.reflect_on_association(:user)

      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    it "requires a name" do
      api_key = build(:api_key, name: nil)

      expect(api_key).not_to be_valid
      expect(api_key.errors[:name]).to include("can't be blank")
    end

    it "requires a client_id" do
      api_key = build(:api_key, client_id: nil)
      api_key.valid?

      expect(api_key.client_id).to start_with("bc_")
    end

    it "requires a unique client_id" do
      create(:api_key, client_id: "dup")
      api_key = build(:api_key, client_id: "dup")

      expect(api_key).not_to be_valid
      expect(api_key.errors[:client_id]).to include("has already been taken")
    end
  end

  describe "callbacks" do
    describe "#generate_client_id" do
      it "generates a client_id on create if not provided" do
        api_key = build(:api_key, client_id: nil)
        api_key.valid?
        expect(api_key.client_id).to start_with("bc_")
        expect(api_key.client_id.length).to eq(35)
      end

      it "does not override provided client_id" do
        api_key = build(:api_key, client_id: "custom_id")
        api_key.valid?
        expect(api_key.client_id).to eq("custom_id")
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      let(:user) { create(:user) }

      it "returns keys without expiration" do
        active_key = create(:api_key, user: user, expires_at: nil)
        expect(described_class.active).to include(active_key)
      end

      it "returns keys with future expiration" do
        future_key = create(:api_key, user: user, expires_at: 1.day.from_now)
        expect(described_class.active).to include(future_key)
      end

      it "excludes expired keys" do
        expired_key = create(:api_key, user: user, expires_at: 1.day.ago)
        expect(described_class.active).not_to include(expired_key)
      end
    end
  end

  describe "#expired?" do
    it "returns false when expires_at is nil" do
      api_key = build(:api_key, expires_at: nil)
      expect(api_key.expired?).to be false
    end

    it "returns false when expires_at is in the future" do
      api_key = build(:api_key, expires_at: 1.day.from_now)
      expect(api_key.expired?).to be false
    end

    it "returns true when expires_at is in the past" do
      api_key = build(:api_key, expires_at: 1.day.ago)
      expect(api_key.expired?).to be true
    end
  end

  describe "#touch_last_used!" do
    it "updates last_used_at and last_used_ip" do
      api_key = create(:api_key)
      ip = "192.168.1.1"

      freeze_time do
        api_key.touch_last_used!(ip)

        expect(api_key.last_used_at).to eq(Time.current)
        expect(api_key.last_used_ip).to eq(ip)
      end
    end
  end

  describe "secret key authentication" do
    it "authenticates with correct secret key" do
      api_key = build(:api_key)
      api_key.secret_key = "test_secret_key"
      api_key.secret_key_confirmation = "test_secret_key"
      api_key.save!

      expect(api_key.authenticate_secret_key("test_secret_key")).to eq(api_key)
    end

    it "fails authentication with incorrect secret key" do
      api_key = build(:api_key)
      api_key.secret_key = "test_secret_key"
      api_key.secret_key_confirmation = "test_secret_key"
      api_key.save!

      expect(api_key.authenticate_secret_key("wrong_key")).to be false
    end
  end
end
