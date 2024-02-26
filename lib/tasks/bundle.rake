namespace :bundle do
  desc "Audit bundle for any known vulnerabilities"
  task :audit do
    unless system "bundle-audit check --update -i CVE-2024-26143"
      exit 1
    end
  end
end
