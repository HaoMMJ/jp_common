class Dictionary < ApplicationRecord
  has_many :dic_vocabs
  has_many :vocabularies, through: :dic_vocabs
end