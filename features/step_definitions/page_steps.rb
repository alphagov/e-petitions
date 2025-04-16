Given('the {string} page is disabled') do |slug|
  Page.where(slug: slug).update_all(enabled: false)
end

Given('the {string} page is redirected to {string}') do |slug, url|
  Page.where(slug: slug).update_all(redirect: true, redirect_url: url)
end
