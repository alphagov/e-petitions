class DepartmentPetitionSearch < PetitionSearch

  private

  def execute_search_query
    Petition.search do |query|
      query.fulltext search_term
      query.facet :state
      query.paginate page: @params[:page], per_page: 20
      case state
      when State::CLOSED_STATE
        query.with(:state).equal_to("open")
        query.with(:closed_at).less_than(Time.current.utc)
      when State::REJECTED_STATE
        query.with(:state).equal_to("rejected")
      when State::OPEN_STATE
        query.with(:state).equal_to("open")
        query.with(:closed_at).greater_than(Time.current.utc)
      end
       query.order_by *SearchOrder.sort_order(@params, [:score, :desc])
       query.with(:department_id, @params[:id])
    end
  end
end
