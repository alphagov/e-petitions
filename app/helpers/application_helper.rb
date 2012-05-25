module ApplicationHelper
  def increment(amount = 1)
    @counter ||= 0
    @counter += amount
  end

  def new_window_link_to(label, path, options = {})
    link_to raw(label + ' <span class="new_window_icon">This link opens in a new window</span>'), path, options.merge(:target => '_blank')
  end

  def info_link_to(path, options = {})
    options[:class] = ("info_link " + options[:class]).strip
    link_to "Click for more information", path, {:title => 'Click for more information'}.merge(options)
  end

  def http_prefix
    request.ssl? ? "https://" : "http://"
  end

  RESULT_LIST_OPTIONS = {
    "open"     => "Listed below are any e-petitions that can be signed.",
    "closed"   => "Listed below are any e-petitions that have ended. These can no longer be signed.",
    "rejected" => "Listed below are the e-petitions that failed to meet the terms and conditions.",
  }

  def results_list_label(state)
    RESULT_LIST_OPTIONS[state]
  end
end
