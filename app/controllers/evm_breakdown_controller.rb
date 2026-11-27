# Abstract base controller for the EVM "breakdown by X" pages: by assignee,
# by version, by tracker and by parent issue (EvmassigneesController,
# EvmversionsController, EvmtrackersController, EvmparentissuesController).
#
# The four pages share the same steps: read the selected id(s) from params,
# build the selectable list, fetch issues/costs for every selected id,
# calculate EVM and build chart data. Each subclass only implements the
# methods that differ. Not routed directly -- see config/routes.rb.
#
# `menu_item :issuevm` is declared in each subclass, not here: Redmine keeps
# it in a class-level instance variable, which subclasses do not inherit.
class EvmBreakdownController < BaseevmController
  # Permission: view_evms (init.rb), same as the main EVM page.
  # Unlike menu_item, before_action is inherited, so this covers all four
  # subclasses.
  before_action :authorize

  # View of the breakdown page.
  #
  # 1. set options of view request
  # 2. get selectable list
  # 3. calculate EVM of each selected id
  #
  def index
    # View options
    assign_view_options
    # selectable list
    @selectable_options = selectable_options
    # an id that the page does not offer is not found
    return render_404 unless selected_ids_offered?

    # calculate EVM (one per selected id)
    @evm_data = {}
    @evm_chart_data = {}
    create_evm_data if selected_ids.present?
  end

  private

  # Set the options of the view request to the cfg_param.
  def assign_view_options
    @cfg_param[:basis_date] = basis_date_or_today
    @cfg_param[breakdown_param] = params[breakdown_param]
    # For back to mainpage
    @cfg_param[:no_use_baseline] = params[:no_use_baseline]
    @cfg_param[:display_explanation] = params[:display_explanation]
  end

  # ---- template methods: every subclass implements these four ----

  # @return [Symbol] the request/cfg_param key holding the selected id(s)
  def breakdown_param
    raise NotImplementedError, "#{self.class} must implement #breakdown_param"
  end

  # @return [Object] the selectable list for the view's <select>
  def selectable_options
    raise NotImplementedError, "#{self.class} must implement #selectable_options"
  end

  # The ids that the page offers for selection, as strings. A page returns nil to accept any id.
  #
  # @return [Array<String>, nil] ids that may be selected, or nil for no restriction
  def offered_ids
    nil
  end

  # @param [String] id one selected id, as received from params
  # @return [Array(Issue, Hash, String)] issues, costs and EVM description for that id
  def evm_inputs_for(id)
    raise NotImplementedError, "#{self.class} must implement #evm_inputs_for"
  end

  # ---- shared implementation ----

  def selected_ids
    @cfg_param[breakdown_param]
  end

  # Whether every selected id is one that the page offers (see #offered_ids). The id is looked up
  # with no other check of the project, so an id of a project that the user may not see would
  # otherwise show its name and EVM values.
  def selected_ids_offered?
    offered = offered_ids
    offered.nil? || Array(selected_ids).all? { |id| offered.include?(id.to_s) }
  end

  # Create evm data
  #
  # 1. evm data
  # 2. chart data
  #
  def create_evm_data
    Array(selected_ids).each do |id|
      issues, costs, description = evm_inputs_for(id)
      evm = CalculateEvmLogic::CalculateEvm.new(nil, issues, costs, @cfg_param)
      evm.description = description
      @evm_data[id] = evm
      @evm_chart_data[id] = ChartDataMaker.evm_chart_data(evm)
    end
  end
end
