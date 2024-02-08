namespace :bundle do
  desc "Audit bundle for any known vulnerabilities"
  task :audit do
    unless system "bundle-audit check --update -i GHSA-xc9x-jj77-9p9j"
      exit 1
    end
  end
end
