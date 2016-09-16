class CreateKanjiDictionary < ActiveRecord::Migration[5.0]
  def change
    create_table :kanji_dictionaries do |t|
      t.string :kanji
      t.string :kanji_mean
      t.text :mean
      t.string :onyomi
    end
  end
end
