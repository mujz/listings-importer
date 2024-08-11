# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 7.2.0"
gem "pg", "~> 1.1"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false
gem "csv"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: [:mri, :windows], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  gem "rubocop-shopify", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false

  gem "rspec-rails"
end
