class CreateExample < ActiveRecord::Migration[5.0]
  def change
    create_table :examples do |t|
      t.references :meaning
      t.text   :content
      t.text   :mean
      t.text   :transcription
    end
  end
end
