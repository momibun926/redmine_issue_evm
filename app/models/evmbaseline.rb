# baseline model
class Evmbaseline < ActiveRecord::Base
  unloadable

  # Relations
  belongs_to :author, class_name: 'User'
  belongs_to :project
  has_many :evmbaselineIssues, dependent: :delete_all

  # attribute
  attr_protected :id

  # Validate
  validates :subject, presence: true

  # Minimum start date of baseline.
  #
  # @return [date] minimum of start date
  def minimum_start_date
    evmbaselineIssues.minimum(:start_date)
  end

  # maximum due date of baseline.
  #
  # @return [date] maximum of due date
  def maximum_due_date
    evmbaselineIssues.maximum(:due_date)
  end

  # BAC of baseline.
  #
  # @return [numeric] BAC of baseline
  def bac
    evmbaselineIssues.sum(:estimated_hours).round(1)
  end

  # for activity page.
  acts_as_event title: Proc.new { |o| l(:title_evm_tab) + ' : ' +
                                      o.subject + ' : ' +
                                      (o.created_on < o.updated_on ? l(:label_ativity_message_edit) : l(:label_ativity_message_new))},
                description: :description,
                datetime: :updated_on,
                type: Proc.new { |o| 'evmbaseline-' + (o.created_on < o.updated_on ? 'edit' : 'new') },
                url: Proc.new { |o| { controller: 'evmbaselines', action: :show, project_id: o.project, id: o.id } }

  acts_as_activity_provider scope: joins(:project),
                            permission: :view_evmbaselines,
                            type: 'evmbaseline',
                            author_key: :author_id

  # for search.
  acts_as_searchable columns: ["#{table_name}.subject", "#{table_name}.description"],
                     :preload => [ :project ],
                     date_column: :updated_on
  # scope
  scope :visible, lambda {|*args|
    joins(:project).
    where(Project.allowed_to_condition(args.shift || User.current, :view_evmbaselines, *args))}

end
