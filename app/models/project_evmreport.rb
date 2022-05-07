# project evmreport model
class ProjectEvmreport < ActiveRecord::Base
  # Relations
  belongs_to :author, class_name: "User"
  belongs_to :project

  # Validate
  validates :project_id,
            presence: true

  validates :status_date,
            presence: true

  validates :report_text,
            presence: true

  # for activity page.
  acts_as_event title: Proc.new { |o| (o.created_on < o.updated_on ? l(:label_ativity_message_report_edit) : l(:label_ativity_message_report_new)) },
                description: :report_text,
                datetime: :updated_on,
                type: Proc.new { |o| "evmreports-#{o.created_on < o.updated_on ? 'edit' : 'new'}" },
                url: Proc.new { |o| { controller: "evmreports", action: :show, project_id: o.project, id: o.id } }

  acts_as_activity_provider scope: joins(:project),
                            permission: :view_project_evmreports,
                            type: "project_evmreport",
                            author_key: :author_id

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
        ->(*args) { joins(:project).where(Project.allowed_to_condition(args.shift || User.current, :view_project_evmreports, *args)) }
end
