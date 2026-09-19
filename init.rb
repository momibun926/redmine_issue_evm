require "redmine"
require "holidays/core_extensions/date"

# Extention for ate class
class Date
  include Holidays::CoreExtensions::Date
end

# for search and activity page
if Rails.version > "6.0" && Rails.autoloaders.zeitwerk_enabled?
  Redmine::Activity.register "evmbaseline"
  Redmine::Activity.register "project_evmreport"
  Redmine::Search.available_search_types << "evmbaselines"
  Redmine::Search.available_search_types << "project_evmreports"
else
  Rails.configuration.to_prepare do
    Redmine::Activity.register "evmbaseline"
    Redmine::Activity.register "project_evmreport"
    Redmine::Search.available_search_types << "evmbaselines"
    Redmine::Search.available_search_types << "project_evmreports"
  end
end

# module define
Redmine::Plugin.register :redmine_issue_evm do
  name "Redmine Issue Evm plugin"
  author "Hajime Nakagama"
  description "Earned value management calculation plugin."
  version "6.0.2"
  url "https://github.com/momibun926/redmine_issue_evm"
  author_url "https://github.com/momibun926"
  project_module :Issuevm do
    # view_evms also covers the read-only pages that used to have no
    # `permission` entry at all -- the assignee/version/tracker/parent_issue
    # breakdown pages, the excluded-issues list and the baseline diff detail
    # view. See the current-state analysis doc, section 13: none of these
    # controllers called `before_action :authorize` before, so this
    # permission was never actually enforced for them.
    # Not `permission :view_evms, { evms: :index, ... }, require: :member`:
    # the original had no braces around the actions hash, which in plain
    # Ruby means `evms: :index, require: :member` collapses into ONE hash
    # literal (permission gets 2 args total: the name and that hash), not
    # two separate hash arguments. Braced, this would instead pass 3
    # arguments (name, actions hash, options hash) -- a different call
    # shape than what this plugin has run with. Kept unbraced so every new
    # controller:action pair joins that same single hash exactly like
    # `require: :member` already did, rather than risk changing how
    # Redmine's own `permission` method receives :require.
    permission :view_evms,
               evms: :index,
               evmassignees: :index,
               evmversions: :index,
               evmtrackers: :index,
               evmparentissues: :index,
               evmexcludes: :index,
               evmbaselinediffdetails: :index,
               require: :member
    permission :manage_evmbaselines,
               evmbaselines: %i[edit destroy new create update index show history]
    permission :view_evmbaselines,
               evmbaselines: %i[index history show]
    # Was `evmsettings: %i[ndex edit]` -- "ndex" is a typo of "index", but
    # EvmsettingsController has no #index action at all, so that entry was
    # dead either way. The real gap was :new/:update/:create having no
    # permission mapped to them, which would have blocked the EVM settings
    # create/update flow entirely once authorize started being enforced.
    permission :manage_evmsettings,
               evmsettings: %i[new edit update create]
    # Added :update -- it was missing, same class of gap as evmsettings above.
    permission :view_project_evmreports,
               evmreports: %i[index show new create edit update destroy]
  end

  # menu
  menu :project_menu, :issuevm, { controller: :evms, action: :index },
       caption: :tab_display_name, param: :project_id

  # load holidays
  Holidays.load_all
end
