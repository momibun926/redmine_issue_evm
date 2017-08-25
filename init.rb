require 'redmine'
require 'holidays/core_extensions/date'

#Extention for ate class
class Date
  include Holidays::CoreExtensions::Date
end

#for search and activity page
Rails.configuration.to_prepare do
  Redmine::Activity.register 'evmbaseline'
  Redmine::Search.available_search_types << 'evmbaselines'
end

# module define
Redmine::Plugin.register :redmine_issue_evm do
  name 'Redmine Issue Evm plugin'
  author 'Hajime Nakagama'
  description 'Earned value management calculation plugin.'
  version '4.0'
  url 'https://github.com/momibun926/redmine_issue_evm'
  author_url 'https://github.com/momibun926'

  # module
  project_module :Issuevm do
    permission :view_evms, evms: :index, require: :member
    permission :manage_evmbaselines,
               evmbaselines: [:edit,
                              :destroy,
                              :new,
                              :create,
                              :update,
                              :index,
                              :show,
                              :history]
    permission :view_evmbaselines,
               evmbaselines: [:index,
                              :history,
                              :show]
  end

  # menu
  menu :project_menu, :issuevm, { controller: :evms, action: :index },
       caption: :tab_display_name, param: :project_id

  # setting
  settings default: { working_hours_of_day: '8.0',
                      limit_spi: '0.9',
                      limit_cpi: '0.9',
                      limit_cr: '0.8',
                      region: :jp},
           partial: 'settings/issue_evm_settings'

  # View listener for activity page
  class RedmineIssueEvmHookListener < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, :inline => "<%= stylesheet_link_tag 'issue_evm', :plugin => :redmine_issue_evm %>"
  end

  # load holidays
  Holidays.load_all

end
