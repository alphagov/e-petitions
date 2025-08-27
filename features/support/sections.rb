module SectionHelpers
  def xpath_of_section(section_name, prefix = "//")
    case section_name

    # Non site-specific based
    when /"([^\"]*)" fieldset/
      "#{prefix}fieldset#{XPathHelpers.class_matching($1.downcase.gsub(/\s/, '_'))}"

    # Sitewide
    when /^single h1$/
      expect(page).to have_xpath("//h1", :count => 1)
      "#{prefix}h1"

    else
      raise "Can’t find mapping from \"#{section_name}\" to a section."
    end
  end

  def within_section(section_name)
    within xpath_of_section(section_name) do
      yield
    end
  end
end

World(SectionHelpers)
