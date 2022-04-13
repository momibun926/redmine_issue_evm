# project evmreport model
class ProjectEvmreport < ActiveRecord::Base
  # Validate
  validates :project_id,
            presence: true

  validates :status_date,
            presence: true

  validates :report_text,
            presence: true

  # for search.
  acts_as_searchable columns: ["#{table_name}.report_text"],
                     preload: :project,
                     date_column: :updated_on
  # scope
  scope :list,
        ->(project_id) { where(project_id: project_id).order(status_date: :DESC).order(created_on: :DESC) }

  scope :previus,
        ->(status_date) { where("status_date < ?", status_date) }

  scope :visible,
        ->(*args) { joins(:project).where(Project.allowed_to_condition(args.shift || User.current, :view_evmbaselines, *args)) }
end
