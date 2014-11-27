class Evmbaseline < ActiveRecord::Base
  unloadable
  has_many :evmbaseline_issues
end
