require 'redmine'

Rails.configuration.to_prepare do
  Redmine::Activity.register 'evmbaseline'
  Redmine::Search.available_search_types << 'evmbaseline'
end

Redmine::Plugin.register :redmine_issue_evm do
  name 'Redmine Issue Evm plugin'
  author 'Hajime Nakagama'
  description 'Earned value management calculation plugin.'
  version '3.5.6'
  url 'https://github.com/momibun926/redmine_issue_evm'
  author_url 'https://github.com/momibun926'

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
    permission :view_evm_baselines,
               evmbaselines: [:index,
                              :history,
                              :show]
  end

  menu :project_menu, :issuevm, { controller: :evms, action: :index },
       caption: :tab_display_name, param: :project_id

  settings default: { working_hours_of_day: '8.0',
                      limit_spi: '0.9',
                      limit_cpi: '0.9',
                      limit_cr: '0.8' },
           partial: 'settings/issue_evm_settings'
end
