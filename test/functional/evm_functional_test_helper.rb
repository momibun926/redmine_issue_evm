# Shared support for the functional (controller) tests of this plugin.
#
# Every test runs as a member of the Redmine fixture project 1 ("eCookbook")
# with the plugin's project module enabled and every plugin permission
# granted to the member's role, so the tests reach the controller code
# itself; the permission checks have their own tests.
require File.expand_path("../test_helper", __dir__)

# Fixtures that the plugin's controllers (issues, versions, time entries,
# journals, ...) read through Redmine's models.
module EvmFunctionalTestSupport
  PLUGIN_PERMISSIONS = %i[view_evms manage_evmbaselines view_evmbaselines
                          manage_evmsettings view_project_evmreports].freeze

  def self.included(base)
    base.fixtures :projects, :users, :email_addresses, :user_preferences, :roles, :members,
                  :member_roles, :issues, :issue_statuses, :trackers, :projects_trackers,
                  :enabled_modules, :enumerations, :versions, :workflows, :time_entries,
                  :journals, :journal_details, :issue_categories, :custom_fields,
                  :custom_values, :custom_fields_projects, :custom_fields_trackers
  end

  private

  # Log in as jsmith (member of the scenario project), enable the module,
  # grant the permissions.
  def sign_in_as_project_member
    @project = create_evm_scenario_project
    Role.find(1).add_permission!(*PLUGIN_PERMISSIONS)
    @request.session[:user_id] = 2
  end

  # A project of its own with fixed dates, so the EVM values the pages show
  # do not depend on the day the tests run (the fixture projects' dates are
  # relative to today):
  #
  #   issue 1  Mon 2026-01-05 .. Fri 2026-01-09, 40h, 50% done on 2026-01-07
  #   issue 2  Mon 2026-01-12 .. Fri 2026-01-16, 20h, closed on 2026-01-14
  #   spent    8h on 01-06, 8h on 01-07 (issue 1), 4h on 01-13 (issue 2)
  def create_evm_scenario_project
    project = Project.create!(name: "EVM scenario", identifier: "evm-scenario", is_public: false,
                              enabled_module_names: %w[issue_tracking time_tracking Issuevm],
                              tracker_ids: [1, 2])
    Member.create!(project: project, user_id: 2, role_ids: [1])
    version = Version.create!(project: project, name: "Release 1", effective_date: Date.new(2026, 1, 16))
    @issue1 = create_scenario_issue(project, "Plan the recipes", [Date.new(2026, 1, 5), Date.new(2026, 1, 9)], 40,
                                    fixed_version: version)
    @issue2 = create_scenario_issue(project, "Publish the recipes", [Date.new(2026, 1, 12), Date.new(2026, 1, 16)], 20,
                                    tracker_id: 2, status_id: 5, done_ratio: 100)
    record_progress(@issue1, 50, Time.utc(2026, 1, 7, 3))
    update_issue_columns(@issue2, closed_on: Time.utc(2026, 1, 14, 3))
    create_time_entry(@issue1, Date.new(2026, 1, 6), 8)
    create_time_entry(@issue1, Date.new(2026, 1, 7), 8)
    create_time_entry(@issue2, Date.new(2026, 1, 13), 4)
    project
  end

  # Writes columns directly, without callbacks or validations. (Issue#update_columns
  # silently does nothing here because of the issue's optimistic locking.)
  def update_issue_columns(issue, attributes)
    Issue.where(id: issue.id).update_all(attributes) # rubocop:disable Rails/SkipsModelValidations
    issue.reload
  end

  def create_scenario_issue(project, subject, dates, hours, attributes = {})
    Issue.create!({ project: project, tracker_id: 1, status_id: 1, priority_id: 5, author_id: 2,
                    assigned_to_id: 2, subject: subject, start_date: dates.first, due_date: dates.last,
                    estimated_hours: hours }.merge(attributes))
  end

  # Change the done ratio with a journal entry created at the given time
  def record_progress(issue, done_ratio, time)
    issue.reload
    issue.init_journal(User.find(2))
    issue.done_ratio = done_ratio
    issue.save!
    issue.journals.last.update_columns(created_on: time) # rubocop:disable Rails/SkipsModelValidations
  end

  def create_time_entry(issue, spent_on, hours)
    TimeEntry.create!(project: issue.project, issue: issue, user_id: 2, author_id: 2,
                      activity_id: 9, hours: hours, spent_on: spent_on)
  end

  # A baseline of the scenario project. `plans` is a list of
  # [issue, start_date, due_date, estimated_hours].
  def create_baseline(subject, created_on, plans, project = @project)
    baseline = Evmbaseline.new(project_id: project.id, subject: subject, description: "#{subject} description",
                               state: "current", author_id: 2, based_on: created_on.to_date,
                               created_on: created_on, updated_on: created_on)
    plans.each do |issue, start_date, due_date, hours|
      baseline.evmbaselineIssues << EvmbaselineIssue.new(issue_id: issue.id, start_date: start_date,
                                                         due_date: due_date, estimated_hours: hours,
                                                         leaf: true)
    end
    baseline.save!
    baseline
  end

  # Instance variable of the controller that handled the last request
  def controller_ivar(name)
    @controller.instance_variable_get("@#{name}")
  end

  # The project's EVM plugin setting, as a project member would have saved it.
  def create_evm_setting(attributes = {}, project = @project)
    Evmsetting.create!({ project_id: project.id, user_id: 2,
                         view_forecast: true, view_version: true, view_performance: true,
                         view_issuelist: true, etc_method: "method2", basis_hours: 8,
                         threshold_spi: 0.9, threshold_cpi: 0.9, threshold_cr: 0.9,
                         region: "jp" }.merge(attributes))
  end
end
