class AddColumnEvmbaselines < ActiveRecord::Migration
  def change
    add_column :Evmbaselines :author_id, :integer
    add_column :Evmbaselines :update_id, :integer
    add_column :Evmbaselines :updated_on, :datetime
  end
end
