Gem::Specification.new do |spec|
  spec.name          = 'anki_generator'
  spec.version       = '1.1.0'
  spec.authors       = ['Ceb']
  spec.email         = ['ceeb.developer@gmail.com']
  spec.summary       = 'AI-powered Anki flashcard generator with file attachment support'
  spec.description   = 'A powerful command-line tool that generates Anki flashcard decks (.apkg) from YAML files, direct prompts, or file attachments. Features AI-powered content generation using OpenRouter API with support for multiple models (GPT, Claude, Llama), file and directory attachment processing for context-aware generation, prompt file support, intelligent content filtering, and flexible deck management with sync capabilities.'
  spec.homepage      = 'https://github.com/pinkfloydsito/anki_generator'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb', 'bin/*', 'README.md']
  spec.bindir        = 'bin'
  spec.executables   = ['anki_generator']
  spec.require_paths = ['lib']

  spec.add_dependency 'anki2', '~> 0.1.2'
  spec.add_dependency 'thor', '~> 1.2'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'json', '~> 2.0'
  spec.add_dependency 'dotenv', '~> 2.8'

  spec.add_development_dependency 'minitest', '~> 5.25'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'

  spec.required_ruby_version = '>= 2.7.0'
  
  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'documentation_uri' => "#{spec.homepage}/blob/main/README.md"
  }
end
