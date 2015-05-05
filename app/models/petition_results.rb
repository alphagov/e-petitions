class PetitionResults
  attr_accessor :search_term, :state, :per_page, :page_number,
                :petitions, :state_counts, :sort, :order, :search_strategy

  def initialize(options)
    setup_attributes(options)
    set_defaults
    sanitise_page_number
    search if search_term.present?
  end

  def search
    searcher = search_strategy.new(search_options)
    if(search = searcher.execute(search_term))
      self.petitions    = search.results
      self.state_counts = searcher.state_counts_for(search_term)
    end
  end

  private
  def set_defaults
    self.state ||= Petition::OPEN_STATE
    self.search_term    ||= ""
    self.state_counts   = Hash.new(0)
    self.search_strategy ||= Search
    self.petitions = []
  end

  def sanitise_page_number
    self.page_number = self.page_number.to_i
    self.page_number = 1 if self.page_number < 1
  end

  def setup_attributes(options)
    options.each do |key, value|
      self.send("#{key}=", value) if respond_to? key
    end
  end

  def search_options
    {
      :target             => Petition,
      :sunspot_interface  => Sunspot,
      :state              => state,
      :per_page           => per_page,
      :page               => page_number,
      :sort               => sort,
      :order              => order,
    }
  end

end
