class CreateVocabularies < ActiveRecord::Migration[5.0]
  def change
    create_table :vocabularies do |t|
      t.string :kanji
      t.string :kana
      t.text   :raw
      t.text   :cn_mean
      t.text   :mean
      t.integer :level
      t.string :from_source, default: "mazii"
    end
  end
end
