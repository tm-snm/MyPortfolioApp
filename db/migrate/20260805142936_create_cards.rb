class CreateCards < ActiveRecord::Migration[7.2]
  def change
    create_table :cards do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.text :future_note
      t.text :raw_content
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
