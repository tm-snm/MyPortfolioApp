class CreatePromptTemplatePreferences < ActiveRecord::Migration[7.2]
  def change
    create_table :prompt_template_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.references :prompt_template, null: false, foreign_key: true
      t.boolean :favorite, null: false, default: false
      t.datetime :last_used_at

      t.timestamps

      t.index [ :user_id, :prompt_template_id ],
              unique: true,
              name: "idx_prompt_template_preferences_unique"
    end
  end
end
