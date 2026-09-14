class AddReviewScheduleToCards < ActiveRecord::Migration[7.2]
  def change
    add_column :cards, :next_review_on, :date
    add_column :cards, :last_reviewed_at, :datetime
    add_index :cards, %i[user_id status next_review_on],
              name: "index_cards_on_user_status_next_review"
  end
end
