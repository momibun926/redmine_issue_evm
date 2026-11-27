require File.expand_path("../test_helper", __dir__)
require File.expand_path("evm_plugin_records_helper", __dir__)

# Deleting a project deletes the plugin's records of it (EvmProjectPatch).
class EvmProjectPatchTest < ActiveSupport::TestCase
  include EvmPluginRecordsHelper

  def setup
    @parent = Project.create!(name: "EVM parent", identifier: "evm-parent")
    @child = Project.create!(name: "EVM child", identifier: "evm-child", parent: @parent)
    @other = Project.create!(name: "EVM other", identifier: "evm-other")
    [@parent, @child, @other].each { |project| create_plugin_records(project) }
  end

  def test_deleting_a_project_deletes_its_records_and_those_of_its_subprojects
    @parent.reload.destroy

    [@parent, @child].each { |project| assert_equal [0, 0, 0, 0], plugin_record_counts(project) }
  end

  def test_records_of_other_projects_are_kept
    @parent.reload.destroy

    assert_equal [1, 2, 1, 3], plugin_record_counts(@other)
  end

  def test_deleting_a_subproject_keeps_the_records_of_its_parent
    @child.reload.destroy

    assert_equal [0, 0, 0, 0], plugin_record_counts(@child)
    assert_equal [1, 2, 1, 3], plugin_record_counts(@parent)
  end
end
