# baseline issue model
class EvmbaselineIssue < ActiveRecord::Base
  unloadable

  # Relations
  belongs_to :evmbaseline

  # attribute
  attr_protected :id
end
