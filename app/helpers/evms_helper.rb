module EvmsHelper

  def spi_color
    value = ""
    case @project_evm.today_spi
    when (@limit_spi + 0.01..0.99) then
      value = 'class="indicator-orange"'
    when (0.01..@limit_spi) then
      value = 'class="indicator-red"'
    end
    value.html_safe
  end

  def cpi_color
    value = ""
    case @project_evm.today_cpi
    when (@limit_cpi + 0.01..0.99) then
      value = 'class="indicator-orange"'
    when (0.01..@limit_cpi) then
      value = 'class="indicator-red"'
    end
    value.html_safe
  end

  def cr_color
    value = ""
    if @project_evm.today_sv < 0.0
      case @project_evm.today_cr
      when (@limit_cr + 0.01..0.99) then
        value = 'class="indicator-orange"'
      when (0.01..@limit_cr) then
        value = 'class="indicator-red"'
      end
    end
    value.html_safe
  end

  def project_chart_name
    unless @baseline_id.nil?
      @project.name + ' - ' + @evmbaseline.find(@baseline_id).subject
    else
      @project.name
    end
  end

  def version_chart_name ver_id
    ver = Version.find(ver_id)
    pro = Project.find(ver.project_id)
    pro.name + ' - ' + ver.name
  end

end
