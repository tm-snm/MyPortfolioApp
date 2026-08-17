class CardTagAssigner
  def initialize(user:, card:, tag_names:)
    @user = user
    @card = card
    @tag_names = tag_names
  end

  def call
    tags = normalized_tag_names.map do |name|
      @user.tags.find_or_create_by!(name: name)
    end

    @card.tags = tags
  end

  private

  def normalized_tag_names
    @tag_names.to_s
              .split(",")
              .map(&:strip)
              .reject(&:blank?)
              .uniq
  end
end
