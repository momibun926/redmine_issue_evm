# project evmreport model
class ProjectEvmreport < ActiveRecord::Base
  # Relations
  belongs_to :project

  # Validate
  validates :project_id,
            presence: true

  validates :status_date,
            presence: true

  validates :report_text,
            presence: true
end
