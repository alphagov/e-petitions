include BeValidAsset

BeValidAsset::Configuration.markup_validator_host = 'validator.example.com'
BeValidAsset::Configuration.css_validator_host = 'validator.example.com'
BeValidAsset::Configuration.feed_validator_host = 'validator.example.com'
BeValidAsset::Configuration.enable_caching = true
BeValidAsset::Configuration.cache_path = File.join(Rails.root.to_s, %w(tmp be_valid_asset_cache))
BeValidAsset::Configuration.display_invalid_lines = true
