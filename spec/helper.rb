require 'bundler/setup'
require 'simplecov'
require 'coveralls'

SimpleCov.start do
  formatter SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  add_filter "/spec"
  # Different ruby versions calculate different coverage values.
  # To keep build from failing allow small drops:
  maximum_coverage_drop 5
end

Bundler.require(:default, :development)

