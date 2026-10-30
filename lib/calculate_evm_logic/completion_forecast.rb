module CalculateEvmLogic
  # Forecasts of the completion of the project: ETC, EAC, VAC, TEAC, TVAC and the forecast finish date.
  # Mixed into CalculateEvmLogic::CalculateEvm, whose instance variables the methods use.
  module CompletionForecast
    # Estimate to Complete
    # Estimate to Complete (ETC) is the estimated cost required
    # to complete the remainder of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] (BAC - EV) / CPI
    def etc(hours = 1)
      return 0.0 if today_cpi(hours).zero? || today_cr(hours).zero?

      div_value = etc_div_value(hours)
      etc = (bac(hours) - today_ev(hours)) / div_value
      etc.round(1)
    end

    # Estimate at Completion
    # Estimate at Completion (EAC) is the estimated cost of the project
    # at the end of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] BAC - EAC
    def eac(hours = 1)
      eac = today_ac(hours) + etc(hours)
      eac.round(1)
    end

    # Time estimate at completion (TEAC).
    # Whereas the estimated time at completion has to be called the time estimate at completion (TEAC)
    #
    # @return [Numeric] SAC / TPI
    def teac
      teac = today_tpi.zero? ? 0 : @pv.sac / today_tpi
      teac.round(0)
    end

    # Variance at Completion
    # Variance at completion (VAC) is the variance
    # on the total budget at the end of the project.
    #
    # @param [Numeric] hours hours per day
    # @return [Numeric] BAC - EAC
    def vac(hours = 1)
      vac = bac(hours) - eac(hours)
      vac.round(1)
    end

    # Time Variance at Completion (TVAC)
    # Indication of the estimated amount of time
    # that the project will be completed ahead or behind schedule.
    #
    # @return [Numeric] SAC - TEAC
    def tvac
      tvac = @pv.sac - teac
      tvac.round(1)
    end

    # forecast date (Delay)
    #
    # @return [Numeric] delay days
    def delay
      (forecast_finish_date - @pv.due_date).to_i
    end

    # End of project day.(forecast)
    #
    # @return [date] End of project date
    def forecast_finish_date
      # already finished project
      return @ev.max_date if format("%.1f", complete_ev) == "100.0"

      # not worked yet
      return @pv.due_date if today_ev.zero?

      # before schedule date
      return @basis_date if @basis_date < @pv.start_date

      @pv.due_date < @basis_date ? overdue_forecast_finish_date : in_progress_forecast_finish_date
    end

    # rest days
    #
    # @param [Numeric] pv_value pv
    # @param [Numeric] ev_value ev
    # @param [Numeric] spi_value spi
    # @param [Numeric] basis_hours hours of per day is plugin setting
    # @return [date] rest days
    def rest_days(pv_value, ev_value, spi_value, basis_hours)
      ((pv_value - ev_value) / spi_value / basis_hours).round(0)
    end

    # div value fo etc
    #
    # @param [Numeric] hours hours per day
    # @return [nymeric] div value
    def etc_div_value(hours = 1)
      case @etc_method
      when "method1"
        1.0
      when "method2"
        today_cpi(hours)
      when "method3"
        today_cr(hours)
      else
        today_cpi(hours)
      end
    end

    private

    # forecast finish date, after completion schedule date.
    #
    # @return [date] basis date + rest days
    def overdue_forecast_finish_date
      @basis_date + rest_days(@pv.cumulative[@pv.due_date],
                              @ev.cumulative.values.max,
                              today_spi,
                              @working_hours)
    end

    # forecast finish date, until completion schedule date.
    #
    # @return [date] due date + rest days
    def in_progress_forecast_finish_date
      @pv.due_date + rest_days(today_pv, today_ev, today_spi, @working_hours)
    end
  end
end
