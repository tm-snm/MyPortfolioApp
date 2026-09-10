class AddLearningMetadataToCards < ActiveRecord::Migration[7.2]
  def change
    add_column :cards, :understanding_level, :integer
    add_column :cards, :importance, :integer
  end
end
