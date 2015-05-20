Before do
  if Petition.respond_to?(:remove_all_from_index!)
    Petition.remove_all_from_index!
  end
end
