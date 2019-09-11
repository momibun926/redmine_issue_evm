# add column for evm setting page
#
class AddColumnEvmsettings < ActiveRecord::Migration
  def change
    add_column :evmsettings, :exclude_holidays, :boolean
  end
end
