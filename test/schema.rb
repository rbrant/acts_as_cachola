ActiveRecord::Schema.define(:version => 0) do
  create_table :cached_things, :force => true do |t|
    t.string :name
    t.timestamps
  end
  
  create_table :cached_other_things, :force => true do |t|
    t.string :name
    t.timestamps
  end
end