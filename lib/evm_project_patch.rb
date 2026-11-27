# Delete the plugin's records together with the project.
#
# The plugin's models only declare `belongs_to :project`, so Redmine's
# Project#destroy did not see them and left them behind. Included into
# Project from init.rb.
module EvmProjectPatch
  extend ActiveSupport::Concern

  included do
    has_many :evmsettings, class_name: "Evmsetting", dependent: :delete_all
    # destroy, not delete_all: each baseline deletes its baseline issues.
    has_many :evmbaselines, class_name: "Evmbaseline", dependent: :destroy
    has_many :project_evmreports, class_name: "ProjectEvmreport", dependent: :delete_all
  end
end
