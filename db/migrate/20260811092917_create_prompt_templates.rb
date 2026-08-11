class CreatePromptTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :prompt_templates do |t|
      t.string :title, null: false
      t.string :category, null: false
      t.text :description
      t.text :body, null: false

      t.timestamps
    end
  end
end
