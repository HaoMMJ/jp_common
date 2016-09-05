class CreateKanjiSample < ActiveRecord::Migration[5.0]
  def change
    create_table :kanji_samples do |t|
      t.references :jlpt_kanji
      t.string :word
      t.string :kana
      t.string :am_han
      t.text   :meaning
    end
  end
end
