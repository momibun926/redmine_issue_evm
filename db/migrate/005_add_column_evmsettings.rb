# add column for evm setting page
#
class AddColumnEvmsettings < ActiveRecord::Migration[4.2]
  def change
    add_column :evmsettings, :exclude_holidays, :boolean
  end
end
