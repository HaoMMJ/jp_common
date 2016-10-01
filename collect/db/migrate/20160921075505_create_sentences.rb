class CreateSentences < ActiveRecord::Migration[5.0]
  def change
    create_table :sentences do |t|
      t.references :mean
      t.text   :content
      t.text   :translation
    end
  end
end
