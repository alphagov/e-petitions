Before("@departments") do
  ['Cabinet Office', 'Treasury'].each do |department_name|
    FactoryGirl.create(:department, :name => department_name)
  end
end

Before do
  if Petition.respond_to?(:remove_all_from_index!)
    Petition.remove_all_from_index!
  end
end
