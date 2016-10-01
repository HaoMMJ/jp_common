class Mean < ApplicationRecord
  belongs_to :vocabulary
  has_many :sentences
end