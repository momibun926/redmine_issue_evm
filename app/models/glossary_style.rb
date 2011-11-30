class GlossaryStyle < ActiveRecord::Base
  unloadable

  GroupByNone = 0
  GroupByCategory = 1
  GroupByProject = 2

  ProjectCurrent = 0
  ProjectMine = 1
  ProjectAll = 2
  
  belongs_to :project

  
  def grouping?
    case groupby
    when GroupByCategory
      return true
    when GroupByProject
      return (project_scope != ProjectCurrent)
    end
    return false
  end

  def set_default!
    self['show_desc'] = false
    self['groupby'] = 1
    self['project_scope'] = 0
    self['sort_item_0'] = ''
    self['sort_item_1'] = ''
    self['sort_item_2'] = ''
  end

  def sort_params
    ary = []
    for cnt in 0...3
      prm = self["sort_item_#{cnt}"]
      if (prm and !prm.empty?)
        case prm
        when 'project'
          next	if (groupby == GroupByProject or project_scope == ProjectCurrent)
        when 'category'
          next	if (groupby == GroupByCategory)
        end
        ary << prm
      end
    end
    ary.uniq
  end
  
end
