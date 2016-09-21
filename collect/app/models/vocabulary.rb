class Vocabulary < ApplicationRecord
  has_many :dic_vocabs
  has_many :dictionaries, through: :dic_vocabs
  has_many :means
end