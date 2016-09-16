class AddSourceToRawDictionary < ActiveRecord::Migration[5.0]
  def change
    add_column :raw_dictionaries, :source, :string, :default => "mazii"
  end
end
