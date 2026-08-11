class PromptTemplate < ApplicationRecord
  validates :title, :category, :body, presence: true
end
