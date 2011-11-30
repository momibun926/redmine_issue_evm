# 
# category_terms.rb
# 
# Author : Mitsuyoshi Yoshida
# This program is freely distributable under the terms of an MIT-style license.
# 

require 'i18n'

class GroupingTerms
  attr_reader :type, :target
  attr_accessor :ary
  
  def initialize(type, target)
    @type = type
    @target = target
    @ary = []
  end

  def name
    (@target) ? @target.name : I18n.t(:label_not_categorized)
  end

  def <=>(rhterm)
    if (!@target and !rhterm.target)
      return 0
    elsif (!@target or !rhterm.target)
      return -1 if @target
      return 1 if rhterm.target
    end
    case type
    when GlossaryStyle::GroupByCategory
      @target.position <=> rhterm.target.position
    when GlossaryStyle::GroupByProject
      @target.identifier <=> rhterm.target.identifier
    end
  end

  def self.flatten(gtarmsary)
    flatary = []
    gtarmsary.each {|gtarmsary|
      return gtarmsary	unless gtarmsary.is_a?(GroupingTerms)
      flatary += gtarmsary.ary
    }
    flatary
  end
  
end


