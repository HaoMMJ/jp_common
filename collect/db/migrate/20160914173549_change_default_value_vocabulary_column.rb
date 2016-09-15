class ChangeDefaultValueVocabularyColumn < ActiveRecord::Migration[5.0]
  def change
    change_column :vocabularies, :from_source, :string, :default => "mazii"
  end
end
