module EvmsHelper

  def spi_color
    value = ""
    case @project_evm.today_spi(8)
    when (0.81..0.99) then
      value = 'class="indicator-orange"'
    when (0.01..0.8) then
      value = 'class="indicator-red"'
    end
    value.html_safe
  end

  def cpi_color
    value = ""
    case @project_evm.today_cpi(8)
    when (0.91..0.99) then
      value = 'class="indicator-orange"'
    when (0.01..0.90) then
      value = 'class="indicator-red"'
    end
    value.html_safe
  end

  def cr_color
    value = ""
    if @project_evm.today_sv(8) < 0.0
      case @project_evm.today_cr(8)
      when (1.01..100) then
        value = 'class="indicator-orange"'
      when (0.01..0.99) then
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

  def version_chart_name version
    @project.name + ' - ' + version.name
  end

end
