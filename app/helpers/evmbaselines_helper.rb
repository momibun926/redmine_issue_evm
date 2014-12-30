module EvmbaselinesHelper


  def include_sub_project falg
    if falg
      l(:label_sub_include)
    else
      l(:label_sub_exclude)
    end
  end


end
