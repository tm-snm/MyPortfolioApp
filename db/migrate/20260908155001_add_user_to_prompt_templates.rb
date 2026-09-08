class AddUserToPromptTemplates < ActiveRecord::Migration[7.2]
  def change
    add_reference :prompt_templates, :user, null: true, foreign_key: true
  end
end
