RSpec.describe CardTagAssigner do
  let(:user) { create(:user) }
  let(:card) { create(:card, user: user) }

  describe "#call" do
    it "タグ名を正規化してカードへ設定する" do
      described_class.new(
        user: user,
        card: card,
        tag_names: " Rails, Docker, Rails, "
      ).call

      expect(card.tags.pluck(:name)).to contain_exactly(
        "Rails",
        "Docker"
      )
    end
  end
end
