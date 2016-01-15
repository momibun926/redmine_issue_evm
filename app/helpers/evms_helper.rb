# evms helper
module EvmsHelper
  # SPI color of CSS.
  #
  # @return [String] SPI color
  def spi_color
    value = ''
    case @project_evm.today_spi
    when (@limit_spi + 0.01..0.99) then
      value = 'class="indicator-orange"'
    when (0.01..@limit_spi) then
      value = 'class="indicator-red"'
    end
    value.html_safe
  end

  # CPI color of CSS.
  #
  # @return [String] CPI color
  def cpi_color
    value = ''
    case @project_evm.today_cpi
    when (@limit_cpi + 0.01..0.99) then
      value = 'class="indicator-orange"'
    when (0.01..@limit_cpi) then
      value = 'class="indicator-red"'
    end
    value.html_safe
  end

  # CR color of CSS.
  #
  # @return [String] CR color
  def cr_color
    value = ''
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

  # Get project name
  #
  # @return [String] project name, baseline subject
  def project_chart_name
    if @baseline_id.nil?
      @project.name
    else
      @project.name + ' - ' + @evmbaseline.find(@baseline_id).subject
    end
  end

  # Get project name
  #
  # @param [numeric] ver_id fixed version id
  # @return [String] project name, baseline subject
  def version_chart_name(ver_id)
    ver = Version.find(ver_id)
    pro = Project.find(ver.project_id)
    pro.name + ' - ' + ver.name
  end

  # Get local date time
  #
  # @param [datetime] bldatetime updated or created datetime
  # @return [String] formatted date
  def local_date(bldatetime)
    bldatetime.localtime.strftime('%Y-%m-%d %H:%M:%S') if bldatetime.present?
  end
end
