# add column for evm baseline page
#
class AddBasedonEvmbaselines < ActiveRecord::Migration[4.2]
  # add col for new baseline, and history page.
  def change
    add_column :evmbaselines, :based_on, :date
  end
end
