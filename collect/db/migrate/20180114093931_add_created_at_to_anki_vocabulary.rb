class AddCreatedAtToAnkiVocabulary < ActiveRecord::Migration[5.0]
  def change
    add_column :anki_vocabularies, :created_at, :datetime, null: false, default: Time.zone.now
    add_column :anki_vocabularies, :updated_at, :datetime, null: false, default: Time.zone.now
  end
end
