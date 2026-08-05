require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    it "is valid with valid attributes" do
      user = build(:user)

      expect(user).to be_valid
    end
  end

  describe "email" do
    it "does not allow duplicate email addresses" do
      create(:user, email: "test@example.com")
      duplicate_user = build(:user, email: "test@example.com")

      expect(duplicate_user).to be_invalid
    end
  end
end
