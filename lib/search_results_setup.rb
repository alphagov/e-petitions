module SearchResultsSetup
  def results_for(scope)
    @petition_search = PetitionResults.new(:state => params[:state])
    if (state_valid_for_results?(@petition_search.state))
      order_info = SearchOrder.sort_order(params, [:signature_count, :desc])
      order_by = order_info.join(' ')
      ensure_params_have_order_information(order_info)
      @petition_search.petitions = scope.visible.for_state(@petition_search.state).order(order_by)
    end
    @petition_search.petitions = @petition_search.petitions.paginate(:page => params[:page], :per_page => 20)
    @petition_search.state_counts = {
      State::OPEN_STATE => scope.for_state(State::OPEN_STATE).count,
      State::CLOSED_STATE => scope.for_state(State::CLOSED_STATE).count,
      State::REJECTED_STATE => scope.for_state(State::REJECTED_STATE).count
    }
  end

  def ensure_params_have_order_information(order_info)
    params[:sort] = order_info.first.to_s
    params[:sort].sub!('signature_count', 'count')
    params[:sort].sub!('closed_at', 'closing')
    params[:sort].sub!('created_at', 'created')
    params[:order] = order_info.last.to_s
  end

  def state_valid_for_results?(state)
    [State::OPEN_STATE, State::CLOSED_STATE, State::REJECTED_STATE].include?(state)
  end
end
