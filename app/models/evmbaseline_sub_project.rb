class EvmbaselineSubProject < ActiveRecord::Base
  unloadable

  attr_protected :id

  belongs_to :evmbaseline

end
