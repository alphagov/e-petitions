module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def url_to(page_name)
    case page_name

    when /^the home\s?page$/
      home_url

    when /^the help page$/
      help_url

    when /^the privacy page$/
      privacy_url

    when /^the feedback page$/
      feedback_url

    when /^the all petitions page$/
      petitions_url

    when /^the all petitions JSON page$/
      petitions_url(:json)

    when /^the check for existing petitions page$/
      check_petitions_url

    when /^the new petition page$/
      new_petition_url

    when /^the petition page$/
      petition_url(@petition.id)

    when /^the petition page for "([^\"]*)"$/
      petition_url(Petition.find_by(action: $1))

    when /^the archived petitions page$/
      archived_petitions_url

    when /^the archived petitions JSON page$/
      archived_petitions_url(:json)

    when /^the archived petition page for "([^\"]*)"$/
      archived_petition_url(Archived::Petition.find_by(action: $1))

    when /^the new signature page$/
      new_petition_signature_url(@petition.id)

    when /^the new signature page for "([^\"]*)"$/
      new_petition_signature_url(Petition.find_by(action: $1))

    when /^the Admin (.*)$/i
      admin_url($1)

    when /^the local petitions results page$/
      local_petition_url(@my_constituency.slug)

    when /^the local petitions JSON page$/
      local_petition_url(@my_constituency.slug, :json)

    when /^the all local petitions results page$/
      all_local_petition_url(@my_constituency.slug)

    when /^the all local petitions JSON page$/
      all_local_petition_url(@my_constituency.slug, :json)

    else
      begin
        page_name =~ /^the (.*) page$/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('url').join('_').to_sym)
      rescue NoMethodError, ArgumentError
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end

  def admin_url(admin_page)
    case admin_page

    when /^login page$/
      admin_login_url

    when /^home ?page$/
      admin_root_url

    when /^delayed job page$/
      admin_delayed_web_url

    when /^petition page for "([^\"]*)"$/
      admin_petition_url(Petition.find_by(action: $1))

    when /^all petitions page$/
      admin_petitions_url

    when /^in moderation petitions page$/
      admin_petitions_url(state: 'in_moderation')

    when /^invalidations page$/
      admin_invalidations_url

    when /^users index page$/
      admin_admin_users_url

    when /^new user page$/
      new_admin_admin_user_url

    when /^edit profile page$/
      edit_admin_profile_url(@user)

    when /^edit profile page for "([^\"]*)"$/
      edit_admin_profile_url(AdminUser.find_by(email: $1))

    when /^debate outcomes form page for "([^\"]*)"$/
      admin_petition_debate_outcome_url(Petition.find_by(action: $1))

    when /^email petitioners form page for "([^\"]*)"$/
      new_admin_petition_email_url(Petition.find_by(action: $1))

    when /^government response page for "([^\"]*)"$/
      admin_petition_government_response_url(Petition.find_by(action: $1))

    when /^petition edit details page for "([^\"]*)"$/
      admin_petition_details_url(Petition.find_by(action: $1))

    when /^archived petition page for "([^\"]*)"$/
      admin_archived_petition_url(Archived::Petition.find_by(action: $1))

    when /^archived petition edit details page for "([^\"]*)"$/
      admin_archived_petition_details_url(Archived::Petition.find_by(action: $1))

    when /^parliament page$/
      admin_parliament_url

    else
      raise "Can't find mapping from \"#{admin_page}\" to an Admin path.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(NavigationHelpers)
