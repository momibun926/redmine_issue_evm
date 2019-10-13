# evms helper.
# this helper is common helper. called other helpers.
# 
module EvmsHelper
  # SPI color of CSS.
  #
  # @return [String] SPI color
  def spi_color(evm)
    value = case evm.today_spi
    when (@cfg_param[:limit_spi] + 0.01..0.99)
      'class="indicator-orange"'
    when (0.01..@cfg_param[:limit_spi])
      'class="indicator-red"'
    else
      ""
    end
    value.html_safe
  end
  # CPI color of CSS.
  #
  # @return [String] CPI color
  def cpi_color(evm)
    value = case evm.today_cpi
    when (@cfg_param[:limit_cpi] + 0.01..0.99)
      'class="indicator-orange"'
    when (0.01..@cfg_param[:limit_cpi])
      'class="indicator-red"'
    else
      ""
    end
    value.html_safe
  end
  # CR color of CSS.
  #
  # @return [String] CR color
  def cr_color(evm)
    value = ""
    if evm.today_sv < 0.0
      value = case evm.today_cr
      when (@cfg_param[:limit_cr] + 0.01..0.99)
        'class="indicator-orange"'
      when (0.01..@cfg_param[:limit_cr])
        'class="indicator-red"'
      else
        ""
      end
    end
    value.html_safe
  end
  # Get project name
  #
  # @return [String] project name, baseline subject
  def project_chart_name
    name = if @baseline_id.nil?
      @project.name
    else
      @project.name + "- " + @evmbaseline.find(@baseline_id).subject
    end
  end
  # Get assignee name
  #
  # @param [numeric] assignee_id assignee id
  # @return [String] assignee name, assignee name. "no assigned" if not assigned.
  def assignee_name(assignee_id)
    assignee_id.blank? ? l(:no_assignee) : User.find(assignee_id).name
  end
  # Get parent issue link
  #
  # @param [numeric] parent_issue_id parent issue id
  # @return [issue] parent issue link
  def parent_issue_link(parent_issue_id)
    parent_issue = Issue.find(parent_issue_id)
    link_to(parent_issue_id, issue_path(parent_issue))
  end
  # Get parent issue
  #
  # @param [numeric] parent_issue_id parent issue id
  # @return [issue] parent issue object
  def parent_issue_subject(parent_issue_id)
    Issue.find(parent_issue_id).subject
  end
  # Get selected trackers name
  #
  # @param [array] ids selected tracker ids
  # @return [String] trackers name
  def selected_trackers_name(ids)
    selected = Tracker.select(:name).where(id: ids)
    tracker_name = ""
    selected.each do |trac|
      tracker_name = tracker_name + trac.to_s + " "
    end
    tracker_name
  end
  # Get project name
  #
  # @param [numeric] ver_id fixed version id
  # @return [String] project name, baseline subject
  def version_chart_name(ver_id)
    ver = Version.find(ver_id)
    pro = Project.find(ver.project_id)
    pro.name + " - " + ver.name
  end
  # Get local date time
  #
  # @param [datetime] bldatetime updated or created datetime
  # @return [String] formatted date
  def local_date(bldatetime)
    bldatetime.localtime.strftime("%Y-%m-%d %H:%M:%S") if bldatetime.present?
  end
end
