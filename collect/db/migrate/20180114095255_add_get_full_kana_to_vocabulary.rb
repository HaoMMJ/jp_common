class AddGetFullKanaToVocabulary < ActiveRecord::Migration[5.0]
  # CHECK CRAWLED ALL KANA FROM JISHO OR NOT
  def change
    add_column :vocabularies, :get_full_kana, :boolean, null: false, default: false
  end
end
