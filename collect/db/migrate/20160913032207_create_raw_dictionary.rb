class CreateRawDictionary < ActiveRecord::Migration[5.0]
  def change
    create_table :raw_dictionaries do |t|
      t.string :word
      t.text   :raw
    end
  end
end
