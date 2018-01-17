class CreateAnkiVocabulary < ActiveRecord::Migration[5.0]
  def change
    create_table :anki_vocabularies do |t|
      t.string :word
      t.string :reading
      t.string :kanji_meaning
      t.string :jisho_meaning
      t.text   :mazii_meaning
      t.string :used_meaning
    end
  end
end
