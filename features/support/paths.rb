module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /^the home\s?page$/
      '/'

    when /^the accessibility page$/
      accessibility_path

    when /^the how e-Petitions works page$/
      how_it_works_path

    when /^the terms and conditions page$/
      terms_and_conditions_path

    when /^the privacy policy page$/
      privacy_policy_path

    when /^the crown copyright page$/
      crown_copyright_path

    when /^the FAQ page$/
      faq_path

    when /^the feedback page$/
      feedback_path

    when /^the new petition page$/
      new_petition_path

    when /^the petition page for "([^\"]*)"$/
      petition_path(Petition.find_by_title($1))

    when /^the new signature page for "([^\"]*)"$/
      new_petition_signature_path(Petition.find_by_title($1))

    when /^the search results page$/
      search_path

    when /^the departments page$/
      departments_path
    when /^the department info(rmation)? page$/
      info_departments_path

    when /^the Admin (.*)$/i
      admin_path($1)

    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end

  def admin_path(admin_page)
    case admin_page

    when /^login page$/
      admin_login_path

    when /^home ?page$/
      admin_root_path

    when /^todolist page$/
      admin_root_path

    when /^moderate petitions page for "([^\"]*)"$/
      edit_admin_petition_path(Petition.find_by_title($1))

    when /^threshold page$/
      threshold_admin_petitions_path

    when /^all petitions page$/
      admin_petitions_path

    when /^users index page$/
      admin_admin_users_path

    when /^new user page$/
      new_admin_admin_user_path

    when /^edit profile page$/
      edit_admin_profile_path(@user)

    when /^edit profile page for "([^\"]*)"$/
      edit_admin_profile_path(AdminUser.find_by_email($1))

    when /^reports page$/
      admin_reports_path

    else
      raise "Can't find mapping from \"#{admin_page}\" to an Admin path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
