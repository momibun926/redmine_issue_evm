class Evmbaseline < ActiveRecord::Base
  unloadable
  has_many :evmbaselineIssues
  validates :subject, :presence => true
end
