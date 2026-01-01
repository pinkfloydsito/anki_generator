# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require 'yaml'
require_relative '../lib/anki_generator'

class AnkiGeneratorTest < Minitest::Test
  def setup
    @temp_yaml_file = 'temp_flashcards.yaml'
    @temp_apkg_file = 'temp_deck.apkg'
    @temp_ai_yaml_file = 'temp_ai_flashcards.yaml'
    @temp_sync_file = 'temp_sync_flashcards.yaml'

    # Traditional flashcards format
    @flashcards = [
      { 'front' => 'What is Big O notation?',
        'back' => 'Big O notation is a mathematical notation that describes the limiting behavior of a function when the argument tends towards a particular value or infinity.' },
      { 'front' => 'Define a graph.', 'back' => 'A graph is a collection of vertices connected by edges.' }
    ]

    File.open(@temp_yaml_file, 'w') do |file|
      file.write(@flashcards.to_yaml)
    end

    # AI generation format
    @ai_config = {
      'ai_generation' => {
        'topics' => ['Ruby programming', 'Data structures'],
        'context' => 'Computer science fundamentals',
        'difficulty' => 'medium',
        'count' => 2,
        'save_generated' => false
      },
      'cards' => [
        { 'front' => 'Manual card', 'back' => 'Manual answer' }
      ]
    }

    File.open(@temp_ai_yaml_file, 'w') do |file|
      file.write(@ai_config.to_yaml)
    end

    # Sync test file
    @sync_cards = [
      { 'front' => 'Existing card', 'back' => 'Existing answer' }
    ]

    File.open(@temp_sync_file, 'w') do |file|
      file.write(@sync_cards.to_yaml)
    end
  end

  def teardown
    [@temp_yaml_file, @temp_apkg_file, @temp_ai_yaml_file, @temp_sync_file].each do |file|
      File.delete(file) if File.exist?(file)
    end
    
    # Clean up generated files
    generated_file = @temp_ai_yaml_file.gsub('.yaml', '_generated.yaml')
    File.delete(generated_file) if File.exist?(generated_file)
  end

  def test_fill_cards_traditional_format
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file)
    assert_equal 2, anki_generator.cards.length
    assert_equal 'What is Big O notation?', anki_generator.cards.first['front']
  end

  def test_generate_apkg
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file)
    anki_generator.generate_apkg(output_path: @temp_apkg_file)

    assert File.exist?(@temp_apkg_file), 'The .apkg file should be created'
  end

  def test_add_card
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file)
    initial_count = anki_generator.cards.length
    
    anki_generator.add_card(front: 'New question', back: 'New answer')
    
    assert_equal initial_count + 1, anki_generator.cards.length
    assert_equal 'New question', anki_generator.cards.last['front']
    assert_equal 'New answer', anki_generator.cards.last['back']
  end

  def test_ai_generation_without_api_key
    # Test that it handles missing API key gracefully by not processing AI generation
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_ai_yaml_file)
    
    # Should only have the manual cards since no API key provided
    assert_equal 1, anki_generator.cards.length
    assert_equal 'Manual card', anki_generator.cards.first['front']
  end

  def test_ai_generation_with_mock_client
    # Create a simple stub class
    stub_client = Class.new do
      def generate_multiple_flashcards(topics:, context: nil, difficulty: nil, count: nil, attachments: nil)
        [
          { 'front' => 'What is Ruby?', 'back' => 'A programming language' },
          { 'front' => 'What is an array?', 'back' => 'A data structure' }
        ]
      end
    end.new

    # Create a generator without API key first
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_ai_yaml_file)
    
    # Set the stub client and trigger processing
    anki_generator.openrouter_client = stub_client
    anki_generator.process_ai_generation(@ai_config)
    
    # Should have manual card + 2 AI generated cards
    assert_equal 3, anki_generator.cards.length
    assert_equal 'Manual card', anki_generator.cards[0]['front']
    assert_equal 'What is Ruby?', anki_generator.cards[1]['front']
    assert_equal 'What is an array?', anki_generator.cards[2]['front']
  end

  def test_sync_with_existing_deck
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file)
    initial_count = anki_generator.cards.length
    
    anki_generator.sync_with_existing_deck(@temp_sync_file)
    
    # Should have original cards + sync cards
    assert_equal initial_count + 1, anki_generator.cards.length
    
    # Check that existing card was added
    existing_card = anki_generator.cards.find { |card| card['front'] == 'Existing card' }
    refute_nil existing_card
    assert_equal 'Existing answer', existing_card['back']
  end

  def test_sync_prevents_duplicates
    # Add a duplicate card to the main deck
    duplicate_cards = @flashcards + [{ 'front' => 'Existing card', 'back' => 'Different answer' }]
    
    File.open(@temp_yaml_file, 'w') do |file|
      file.write(duplicate_cards.to_yaml)
    end

    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file)
    initial_count = anki_generator.cards.length
    
    anki_generator.sync_with_existing_deck(@temp_sync_file)
    
    # Should not add duplicate (same front text)
    assert_equal initial_count, anki_generator.cards.length
  end

  def test_sync_with_nonexistent_file
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file)
    initial_count = anki_generator.cards.length
    
    # Should handle gracefully
    anki_generator.sync_with_existing_deck('nonexistent_file.yaml')
    
    # Should remain unchanged
    assert_equal initial_count, anki_generator.cards.length
  end

  def test_generate_ai_cards_single_topic
    # Create a simple stub class
    stub_client = Class.new do
      def generate_flashcard(topic:, context: nil, difficulty: nil, attachments: nil)
        { 'front' => 'What is Ruby?', 'back' => 'A programming language' }
      end
    end.new

    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file, api_key: 'test_key')
    anki_generator.openrouter_client = stub_client
    
    result = anki_generator.generate_ai_cards(topics: 'Ruby programming')
    
    assert_equal 1, result.length
    assert_equal 'What is Ruby?', result[0]['front']
  end

  def test_generate_ai_cards_multiple_topics
    # Create a simple stub class
    stub_client = Class.new do
      def generate_multiple_flashcards(topics:, context: nil, difficulty: nil, count: nil, attachments: nil)
        [
          { 'front' => 'What is Ruby?', 'back' => 'A programming language' },
          { 'front' => 'What is an array?', 'back' => 'A data structure' }
        ]
      end
    end.new

    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file, api_key: 'test_key')
    anki_generator.openrouter_client = stub_client
    
    result = anki_generator.generate_ai_cards(topics: ['Ruby', 'Arrays'])
    
    assert_equal 2, result.length
    assert_equal 'What is Ruby?', result[0]['front']
    assert_equal 'What is an array?', result[1]['front']
  end
end
  def test_ai_generation_with_attachments
    # Create a simple stub class that accepts attachments
    stub_client = Class.new do
      def generate_multiple_flashcards(topics:, context:, difficulty:, count:, attachments: nil)
        base_cards = [
          { 'front' => 'What is Ruby?', 'back' => 'A programming language' },
          { 'front' => 'What is an array?', 'back' => 'A data structure' }
        ]
        
        # If attachments provided, add a card about them
        if attachments && !attachments.empty?
          attachment_card = {
            'front' => "What file was attached?",
            'back' => "File: #{attachments.first[:filename]}"
          }
          base_cards << attachment_card
        end
        
        base_cards
      end
    end.new

    # Create a generator without API key first
    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_ai_yaml_file)
    
    # Set the stub client
    anki_generator.openrouter_client = stub_client
    
    # Create mock attachments
    attachments = [
      {
        filename: 'test.rb',
        path: '/path/to/test.rb',
        content: 'puts "Hello, World!"'
      }
    ]
    
    # Process with attachments
    anki_generator.process_ai_generation(@ai_config, attachments: attachments)
    
    # Should have manual card + 3 AI generated cards (including attachment-based card)
    assert_equal 4, anki_generator.cards.length
    assert_equal 'Manual card', anki_generator.cards[0]['front']
    assert_equal 'What is Ruby?', anki_generator.cards[1]['front']
    assert_equal 'What is an array?', anki_generator.cards[2]['front']
    assert_equal 'What file was attached?', anki_generator.cards[3]['front']
    assert_equal 'File: test.rb', anki_generator.cards[3]['back']
  end

  def test_generate_ai_cards_with_attachments
    # Create a simple stub class that accepts attachments
    stub_client = Class.new do
      def generate_flashcard(topic:, context:, difficulty:, attachments: nil)
        if attachments && !attachments.empty?
          { 'front' => "What's in #{attachments.first[:filename]}?", 'back' => 'Code content' }
        else
          { 'front' => 'What is Ruby?', 'back' => 'A programming language' }
        end
      end
    end.new

    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_yaml_file, api_key: 'test_key')
    anki_generator.openrouter_client = stub_client
    
    attachments = [
      {
        filename: 'example.rb',
        path: '/path/to/example.rb',
        content: 'class Example\nend'
      }
    ]
    
    result = anki_generator.generate_ai_cards(
      topics: 'Ruby programming',
      attachments: attachments
    )
    
    assert_equal 1, result.length
    assert_equal "What's in example.rb?", result[0]['front']
    assert_equal 'Code content', result[0]['back']
  end

  def test_process_ai_generation_passes_attachments
    # Test that process_ai_generation properly passes attachments to generate_ai_cards
    stub_client = Class.new do
      attr_reader :last_attachments
      
      def generate_multiple_flashcards(topics:, context:, difficulty:, count:, attachments: nil)
        @last_attachments = attachments
        [{ 'front' => 'Test question', 'back' => 'Test answer' }]
      end
    end.new

    anki_generator = AnkiGenerator.new(name: 'test', deck_file: @temp_ai_yaml_file)
    anki_generator.openrouter_client = stub_client
    
    attachments = [{ filename: 'test.txt', content: 'test content' }]
    
    anki_generator.process_ai_generation(@ai_config, attachments: attachments)
    
    # Verify attachments were passed through
    assert_equal attachments, stub_client.last_attachments
  end