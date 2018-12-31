# evm setting model
class Evmsetting < ActiveRecord::Base

  # Relations
  belongs_to :author, class_name: 'User'
  belongs_to :project

end
