class Evmbaseline < ActiveRecord::Base
  unloadable


  has_many :evmbaselineIssues, :dependent => :delete_all
  has_many :evmbaselineSubProjects, :dependent => :delete_all
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


  def include_sub_projects
    evmbaselineSubProjects.count(:sub_project_id) > 0
  end


end
