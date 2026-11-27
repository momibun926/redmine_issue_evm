# Add indexes on the columns the plugin looks records up by.
#
class AddIndexes < ActiveRecord::Migration[8.1]
  INDEXES = [
    %i[evmbaseline_issues evmbaseline_id],
    %i[evmbaselines project_id],
    %i[evmsettings project_id],
    [:project_evmreports, %i[project_id status_date]]
  ].freeze

  # if_not_exists / if_exists: an administrator may already have added
  # some of these by hand.
  def up
    INDEXES.each { |table, columns| add_index table, columns, if_not_exists: true }
  end

  def down
    INDEXES.each { |table, columns| remove_index table, columns, if_exists: true }
  end
end
