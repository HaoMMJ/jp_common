class CreateJlptKanji < ActiveRecord::Migration[5.0]
  def change
    create_table :jlpt_kanjis do |t|
      t.string :kanji
      t.text   :raw
      t.integer :level
    end
  end
end
