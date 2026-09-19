# Abstract base controller for the EVM "breakdown by X" pages: by assignee,
# by version, by tracker and by parent issue (EvmassigneesController,
# EvmversionsController, EvmtrackersController, EvmparentissuesController).
#
# These four pages used to be four independent, near-identical controllers
# that each repeated the same steps -- read the selected id(s) from params,
# build the selectable list, fetch issues/costs for every selected id,
# calculate EVM and build chart data -- differing only in a handful of
# specifics. One of those differences was a real bug: evmtrackers only
# supported selecting a single tracker while the other three supported
# selecting several, because its `create_evm_data` was never updated to loop
# like the others. This base class factors out everything the four pages
# share; each subclass only implements the four methods below, and gets
# multi-selection for free (and consistently) as a result.
#
# Not routed directly -- see config/routes.rb and the concrete subclasses.
#
# NOTE: `menu_item :issuevm` is intentionally *not* declared here and is left
# to each subclass instead. Redmine's menu_item is set via a plain
# class-level instance variable in Redmine::MenuManager::MenuController,
# which Ruby does not automatically inherit -- every other controller in this
# plugin (including ones outside this hierarchy) declares it individually,
# and this base class follows the same, verified-safe convention rather than
# risk silently breaking project-menu highlighting.
class EvmBreakdownController < BaseevmController
  # View of the breakdown page.
  #
  # 1. set options of view request
  # 2. get selectable list
  # 3. calculate EVM of each selected id
  #
  def index
    # View options
    @cfg_param[:basis_date] = params[:basis_date]
    @cfg_param[breakdown_param] = params[breakdown_param]
    # For back to mainpage
    @cfg_param[:no_use_baseline] = params[:no_use_baseline]
    @cfg_param[:display_explanation] = params[:display_explanation]
    # selectable list
    @selectable_options = selectable_options
    # calculate EVM (one per selected id)
    @evm_data = {}
    @evm_chart_data = {}
    create_evm_data if selected_ids.present?
  end

  private

  # ---- template methods: every subclass implements these four ----

  # @return [Symbol] the request/cfg_param key holding the selected id(s)
  def breakdown_param
    raise NotImplementedError, "#{self.class} must implement #breakdown_param"
  end

  # @return [Object] the selectable list for the view's <select>
  def selectable_options
    raise NotImplementedError, "#{self.class} must implement #selectable_options"
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
