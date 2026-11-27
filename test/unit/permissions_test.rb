require File.expand_path("../test_helper", __dir__)

# The permissions declared in init.rb.
class PermissionsTest < ActiveSupport::TestCase
  fixtures :roles

  def test_view_evms_is_for_members_only
    permission = Redmine::AccessControl.permission(:view_evms)

    assert permission.require_member?
    assert_not_includes permission.actions, "require/member"
    assert_includes permission.actions, "evms/index"
  end

  def test_view_evms_cannot_be_given_to_the_non_member_and_anonymous_roles
    assert_not_includes Role.non_member.setable_permissions.map(&:name), :view_evms
    assert_not_includes Role.anonymous.setable_permissions.map(&:name), :view_evms
    assert_includes Role.find(1).setable_permissions.map(&:name), :view_evms
  end
end
