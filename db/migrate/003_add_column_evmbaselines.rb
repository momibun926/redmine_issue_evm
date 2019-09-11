# add column for actility page
#
class AddColumnEvmbaselines < ActiveRecord::Migration
  # add col for activity page
  def change
    add_column :evmbaselines, :author_id, :integer
    add_column :evmbaselines, :update_id, :integer
    add_column :evmbaselines, :updated_on, :datetime
  end
end
