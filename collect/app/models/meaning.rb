class Meaning < ApplicationRecord
  belongs_to :word
  has_many :examples
end