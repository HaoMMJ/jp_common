class CreateDicVocab < ActiveRecord::Migration[5.0]
  def change
    create_table :dic_vocabs do |t|
      t.references :dictionary
      t.references :vocabulary
    end
  end
end
