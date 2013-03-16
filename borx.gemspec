Gem::Specification.new do |gem|
  gem.name    = 'borx'
  gem.version = '0.0.1.beta2'
  gem.date    = Time.now.strftime("%Y-%m-%d")

  gem.summary = "rewrites ruby code so you can decide what it actually does"
  gem.description = <<'DESCRIPTION'
This plugin parses a piece of ruby code with ripper, rewrites it a bit and converts it back to ruby code.
This lets a central object decide what the code is actually doing.
DESCRIPTION

  gem.authors  = ['Hannes Georg']
  gem.email    = 'hannes.georg@googlemail.com'
  gem.homepage = 'https://github.com/hannesg/borx'

  # ensure the gem is built out of versioned files
  gem.files = Dir['lib/**/*'] & `git ls-files -z`.split("\0")

  gem.add_dependency "sorcerer", "~> 0.3.10"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "simplecov"
end
