class Evmbaseline < ActiveRecord::Base
  unloadable

  attr_protected :id

  has_many :evmbaselineIssues, :dependent => :delete_all
  belongs_to :author, :class_name => 'User'
  belongs_to :project

  validates :subject, :presence => true

  def minimum_start_date
    evmbaselineIssues.minimum(:start_date)
  end

  def maximum_due_date
    evmbaselineIssues.maximum(:due_date)
  end

  def bac
    evmbaselineIssues.sum(:estimated_hours).round(1)
  end

  #acts_as_event :title => 'test',
  #              :description => :subject,
  #              :datetime => :created_on,
  #              :type => Proc.new { |o| 'evmBaseine-' + (o.created_on < o.updated_on ? 'edit' : 'new') },
  #              :url => Proc.new { |o| {:controller => 'EvmbaselinesController', :action => 'index', :id => o.id, :project_id => o.project_id} }

  #acts_as_activity_provider :scope => preload(:projects),
  #                          :author_key => :author_id,
  #                          :timestamp => :created_on,
  #                          :type => :evmbaselines

end
