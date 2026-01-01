# frozen_string_literal: true

require 'thor'
require 'dotenv/load'
require_relative 'anki_generator'
require_relative 'file_processor'

class AnkiCLI < Thor
  desc 'generate DECK_NAME YAML_FILE OUTPUT_FILE', 'Generate an Anki .apkg deck from a YAML file'
  option :api_key, type: :string, desc: 'OpenRouter API key (or set OPENROUTER_API_KEY env var)'
  option :model, type: :string, default: 'openai/gpt-3.5-turbo', desc: 'AI model to use'
  option :sync_with, type: :string, desc: 'Existing YAML file to sync with'
  def generate(deck_name, yaml_file, output_file)
    anki_generator = AnkiGenerator.new(
      name: deck_name, 
      deck_file: yaml_file,
      api_key: options[:api_key],
      model: options[:model]
    )
    
    anki_generator.sync_with_existing_deck(options[:sync_with]) if options[:sync_with]
    anki_generator.generate_apkg(output_path: output_file)
    
    puts "Anki deck '#{deck_name}' has been successfully created as #{output_file}!"
    puts "Total cards: #{anki_generator.cards.length}"
  end

  desc 'generate_yaml PROMPT OUTPUT_YAML', 'Generate a YAML file from a prompt using AI'
  option :api_key, type: :string, desc: 'OpenRouter API key (or set OPENROUTER_API_KEY env var)'
  option :model, type: :string, default: 'openai/gpt-3.5-turbo', desc: 'AI model to use'
  option :difficulty, type: :string, default: 'medium', desc: 'Difficulty level (easy, medium, hard)'
  option :count, type: :numeric, default: 10, desc: 'Number of flashcards to generate'
  option :context, type: :string, desc: 'Additional context for better generation'
  option :attach, type: :array, desc: 'Attach files or directories for context'
  option :prompt_file, type: :boolean, default: false, desc: 'Treat PROMPT as a file path to read from'
  def generate_yaml(prompt, output_yaml)
    begin
      require_relative 'openrouter_client'
      client = OpenRouterClient.new(api_key: options[:api_key], model: options[:model])
      
      # Handle prompt from file
      actual_prompt = if options[:prompt_file]
        puts "📄 Reading prompt from file: #{prompt}"
        FileProcessor.read_prompt_from_file(prompt)
      else
        prompt
      end
      
      # Process attachments
      attachments = nil
      if options[:attach]
        puts "📎 Processing attachments..."
        attachments = FileProcessor.process_attachments(options[:attach])
      end
      
      puts "Generating flashcards for: #{actual_prompt[0..100]}#{'...' if actual_prompt.length > 100}"
      puts "Model: #{client.model}"
      puts "Difficulty: #{options[:difficulty]}"
      puts "Count: #{options[:count]}"
      puts "Attachments: #{attachments&.length || 0} file(s)" if attachments
      puts "Generating..."
      
      # Generate flashcards using the prompt as topics
      cards = client.generate_multiple_flashcards(
        topics: [actual_prompt],
        context: options[:context],
        difficulty: options[:difficulty],
        count: options[:count],
        attachments: attachments
      )
      
      # Create YAML structure
      yaml_content = {
        'ai_generation' => {
          'topics' => [actual_prompt],
          'context' => options[:context],
          'difficulty' => options[:difficulty],
          'count' => options[:count],
          'save_generated' => false
        },
        'cards' => cards
      }
      
      # Write to file
      File.open(output_yaml, 'w') do |file|
        file.write(yaml_content.to_yaml)
      end
      
      puts "✅ Generated #{cards.length} flashcards!"
      puts "YAML file created: #{output_yaml}"
      puts ""
      puts "Preview of generated cards:"
      cards.first(3).each_with_index do |card, index|
        puts "#{index + 1}. #{card['front']}"
        puts "   → #{card['back'][0..100]}#{'...' if card['back'].length > 100}"
        puts ""
      end
      
      puts "To create an Anki deck, run:"
      puts "  anki_generator generate \"My Deck\" #{output_yaml} my_deck.apkg"
      
    rescue => e
      puts "❌ Error generating flashcards: #{e.message}"
      exit 1
    end
  end

  desc 'prompt_to_deck PROMPT DECK_NAME OUTPUT_FILE', 'Generate flashcards from prompt and create deck in one step'
  option :api_key, type: :string, desc: 'OpenRouter API key (or set OPENROUTER_API_KEY env var)'
  option :model, type: :string, default: 'openai/gpt-3.5-turbo', desc: 'AI model to use'
  option :difficulty, type: :string, default: 'medium', desc: 'Difficulty level (easy, medium, hard)'
  option :count, type: :numeric, default: 10, desc: 'Number of flashcards to generate'
  option :context, type: :string, desc: 'Additional context for better generation'
  option :save_yaml, type: :boolean, default: false, desc: 'Save intermediate YAML file'
  option :attach, type: :array, desc: 'Attach files or directories for context'
  option :prompt_file, type: :boolean, default: false, desc: 'Treat PROMPT as a file path to read from'
  def prompt_to_deck(prompt, deck_name, output_file)
    begin
      require_relative 'openrouter_client'
      client = OpenRouterClient.new(api_key: options[:api_key], model: options[:model])
      
      # Handle prompt from file
      actual_prompt = if options[:prompt_file]
        puts "📄 Reading prompt from file: #{prompt}"
        FileProcessor.read_prompt_from_file(prompt)
      else
        prompt
      end
      
      # Process attachments
      attachments = nil
      if options[:attach]
        puts "📎 Processing attachments..."
        attachments = FileProcessor.process_attachments(options[:attach])
      end
      
      puts "🚀 Generating Anki deck from prompt: #{actual_prompt[0..100]}#{'...' if actual_prompt.length > 100}"
      puts "Model: #{client.model}"
      puts "Difficulty: #{options[:difficulty]}"
      puts "Count: #{options[:count]}"
      puts "Attachments: #{attachments&.length || 0} file(s)" if attachments
      puts ""
      
      # Generate flashcards
      puts "Generating flashcards..."
      cards = client.generate_multiple_flashcards(
        topics: [actual_prompt],
        context: options[:context],
        difficulty: options[:difficulty],
        count: options[:count],
        attachments: attachments
      )
      
      puts "✅ Generated #{cards.length} flashcards!"
      
      # Create temporary YAML file
      temp_yaml = "temp_#{Time.now.to_i}.yaml"
      yaml_content = {
        'ai_generation' => {
          'topics' => [actual_prompt],
          'context' => options[:context],
          'difficulty' => options[:difficulty],
          'count' => options[:count],
          'save_generated' => false
        },
        'cards' => cards
      }
      
      File.open(temp_yaml, 'w') do |file|
        file.write(yaml_content.to_yaml)
      end
      
      # Generate Anki deck
      puts "Creating Anki deck..."
      anki_generator = AnkiGenerator.new(
        name: deck_name,
        deck_file: temp_yaml,
        api_key: options[:api_key],
        model: options[:model]
      )
      
      anki_generator.generate_apkg(output_path: output_file)
      
      # Clean up or save YAML
      if options[:save_yaml]
        yaml_file = output_file.gsub('.apkg', '.yaml')
        File.rename(temp_yaml, yaml_file)
        puts "YAML file saved: #{yaml_file}"
      else
        File.delete(temp_yaml)
      end
      
      puts "🎉 Anki deck '#{deck_name}' created successfully!"
      puts "File: #{output_file}"
      puts "Total cards: #{cards.length}"
      puts ""
      puts "Preview of generated cards:"
      cards.first(3).each_with_index do |card, index|
        puts "#{index + 1}. #{card['front']}"
        puts "   → #{card['back'][0..100]}#{'...' if card['back'].length > 100}"
        puts ""
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
      exit 1
    end
  end

  desc 'create_ai_template TEMPLATE_FILE', 'Create a template YAML file for AI generation'
  def create_ai_template(template_file)
    template_content = {
      'ai_generation' => {
        'topics' => ['Example Topic 1', 'Example Topic 2'],
        'context' => 'Additional context for generating flashcards',
        'difficulty' => 'medium',
        'count' => 5,
        'save_generated' => true
      },
      'cards' => [
        {
          'front' => 'Example manual card front',
          'back' => 'Example manual card back'
        }
      ]
    }

    File.open(template_file, 'w') do |file|
      file.write(template_content.to_yaml)
    end

    puts "AI generation template created: #{template_file}"
    puts "Edit the file and run 'anki_generator generate' to create your deck!"
  end

  desc 'test_api', 'Test OpenRouter API connection'
  option :api_key, type: :string, desc: 'OpenRouter API key (or set OPENROUTER_API_KEY env var)'
  option :model, type: :string, default: 'openai/gpt-3.5-turbo', desc: 'AI model to use'
  def test_api
    begin
      require_relative 'openrouter_client'
      client = OpenRouterClient.new(api_key: options[:api_key], model: options[:model])
      
      puts "Testing OpenRouter API connection..."
      puts "Model: #{client.model}"
      
      card = client.generate_flashcard(topic: 'Ruby programming', difficulty: 'easy')
      
      puts "✅ API connection successful!"
      puts "Sample generated card:"
      puts "Front: #{card['front']}"
      puts "Back: #{card['back']}"
      
    rescue => e
      puts "❌ API test failed: #{e.message}"
      exit 1
    end
  end
end