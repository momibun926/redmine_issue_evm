# add column for actility page
#
class AddColumnProjectEvmreports < ActiveRecord::Migration[4.2]
  # add col for activity page
  def change
    add_column :project_evmreports, :author_id, :integer
  end
end
