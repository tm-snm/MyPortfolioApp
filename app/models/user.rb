class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :cards, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :prompt_templates, dependent: :destroy
  has_many :prompt_template_preferences, dependent: :destroy
end
