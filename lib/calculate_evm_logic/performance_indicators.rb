module CalculateEvmLogic
  # Schedule and cost performance indicators (SPI, CPI, CR, TPI, TCPI) and the earned schedule values (ES, AT, TV).
  # Mixed into CalculateEvmLogic::CalculateEvm, whose instance variables the methods use.
  module PerformanceIndicators
    # Earned shedule (ES)
    #
    # @return [Numeric] days
    def today_es
      @pv.today_es(today_ev).to_i
    end

    # Actual time (AT)
    #
    # @return [Numeric] days
    def today_at
      @pv.today_at(@finished_date || @basis_date)
    end

    # Time variance (TV)
    # How much ahead or behind the schedule a project is running on time base.
    #
    # @return [Numeric] days
    def today_tv
      (today_es - today_at).to_i
    end

    # Schedule Performance Indicator
    # Schedule Performance Indicator (SPI) is an index showing
    # the efficiency of the time utilized on the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV / PV on basis date
    def today_spi(hours = 1)
      spi = if today_ev(hours).zero? || today_pv(hours).zero?
              0.0
            else
              today_ev(hours) / today_pv(hours)
            end
      spi.round(2)
    end

    # Time Performance Indicator
    # TPI is greater than 1, then the project is ahead of schedule and
    # if it is less than 1, then the project is behind schedule.
    #
    # @return [Numeric] earned schedule (days) / Actual time (days)
    def today_tpi
      tpi = today_es.zero? ? 0 : today_es.fdiv(today_at)
      tpi.round(2)
    end

    # Cost Performance Indicator
    # Cost Performance Indicator (CPI) is an index showing
    # the efficiency of the utilization of the resources on the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] EV / AC on basis date
    def today_cpi(hours = 1)
      cpi = if today_ev(hours).zero? || today_ac(hours).zero?
              0.0
            else
              today_ev(hours) / today_ac(hours)
            end
      cpi.round(2)
    end

    # Critical ratio
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] SPI * CPI
    def today_cr(hours = 1)
      cr = today_spi(hours) * today_cpi(hours)
      cr.round(2)
    end

    # To Complete Cost Performance Indicator
    # To Complete Cost Performance Indicator (TCPI) is an index showing
    # the efficiency at which the resources on the project should be utilized
    # for the remainder of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] (BAC - EV) / (BAC - AC)
    def tcpi(hours = 1)
      tcpi = if bac(hours).zero?
               0.0
             else
               (bac(hours) - today_ev(hours)) / (bac(hours) - today_ac(hours))
             end
      tcpi.round(1)
    end
  end
end
