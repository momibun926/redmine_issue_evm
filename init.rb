require "redmine"
require "holidays/core_extensions/date"

# Extension for Date class
class Date
  include Holidays::CoreExtensions::Date
end

# for search and activity page
Redmine::Activity.register "evmbaseline", plugin: :redmine_issue_evm
Redmine::Activity.register "project_evmreport", plugin: :redmine_issue_evm
Redmine::Search.available_search_types << "evmbaselines"
Redmine::Search.available_search_types << "project_evmreports"

# delete the plugin's records together with the project
Project.include EvmProjectPatch unless Project.include?(EvmProjectPatch)

# module define
Redmine::Plugin.register :redmine_issue_evm do
  name "Redmine Issue Evm plugin"
  author "Hajime Nakagama"
  description "Earned value management calculation plugin."
  version "7.0.0"
  url "https://github.com/momibun926/redmine_issue_evm"
  author_url "https://github.com/momibun926"
  requires_redmine version_or_higher: "7.0.0"
  project_module :Issuevm do
    # The braces matter: without them, `require: :member` would become part
    # of the actions hash instead of the options.
    permission :view_evms,
               { evms: :index,
                 evmassignees: :index,
                 evmversions: :index,
                 evmtrackers: :index,
                 evmparentissues: :index,
                 evmexcludes: :index,
                 evmbaselinediffdetails: :index },
               require: :member
    permission :manage_evmbaselines,
               evmbaselines: %i[edit destroy new create update index show]
    permission :view_evmbaselines,
               evmbaselines: %i[index show]
    permission :manage_evmsettings,
               evmsettings: %i[new edit update create]
    permission :view_project_evmreports,
               evmreports: %i[index show new create edit update destroy]
  end

  # menu
  menu :project_menu, :issuevm, { controller: :evms, action: :index },
       caption: :tab_display_name, param: :project_id

  # load holidays
  Holidays.load_all
end
