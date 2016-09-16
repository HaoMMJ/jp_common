class CreateJlptWord < ActiveRecord::Migration[5.0]
  def change
    create_table :jlpt_words do |t|
      t.string :word
      t.text   :raw
      t.integer :level
    end
  end
end
