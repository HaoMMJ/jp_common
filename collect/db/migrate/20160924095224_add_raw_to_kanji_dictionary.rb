class AddRawToKanjiDictionary < ActiveRecord::Migration[5.0]
  def change
    add_column :kanji_dictionaries, :raw, :text
  end
end
