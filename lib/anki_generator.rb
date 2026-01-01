# frozen_string_literal: true

require 'yaml'
require 'anki2'
require_relative 'openrouter_client'

# AnkiGenerator -> Class
class AnkiGenerator
  attr_accessor :deck_file, :cards, :name, :openrouter_client

  def initialize(deck_file:, name:, api_key: nil, model: 'openai/gpt-3.5-turbo')
    self.deck_file = deck_file
    self.name = name
    self.cards = []
    self.openrouter_client = OpenRouterClient.new(api_key: api_key, model: model) if api_key || ENV['OPENROUTER_API_KEY']

    fill_cards
  end

  def fill_cards
    yaml_content = YAML.load_file(deck_file)
    
    # Handle both old format (array of cards) and new format (with ai_generation config)
    if yaml_content.is_a?(Hash) && yaml_content['ai_generation']
      process_ai_generation(yaml_content)
    else
      self.cards = yaml_content.is_a?(Array) ? yaml_content : []
    end
  end

  def process_ai_generation(config, attachments: nil)
    ai_config = config['ai_generation']
    existing_cards = config['cards'] || []
    
    # Generate AI cards if specified and client is available
    if ai_config['topics'] && openrouter_client
      ai_cards = generate_ai_cards(
        topics: ai_config['topics'],
        context: ai_config['context'],
        difficulty: ai_config['difficulty'] || 'medium',
        count: ai_config['count'] || 5,
        attachments: attachments
      )
      
      self.cards = existing_cards + ai_cards
    else
      self.cards = existing_cards
    end
    
    # Save the generated cards back to YAML for future reference
    save_generated_cards_to_yaml(config) if ai_config['save_generated'] && openrouter_client
  end

  def generate_ai_cards(topics:, context: nil, difficulty: 'medium', count: 5, attachments: nil)
    if topics.is_a?(Array) && topics.length > 1
      openrouter_client.generate_multiple_flashcards(
        topics: topics,
        context: context,
        difficulty: difficulty,
        count: count,
        attachments: attachments
      )
    else
      topic = topics.is_a?(Array) ? topics.first : topics
      [openrouter_client.generate_flashcard(
        topic: topic,
        context: context,
        difficulty: difficulty,
        attachments: attachments
      )]
    end
  end

  def save_generated_cards_to_yaml(original_config)
    output_file = deck_file.gsub('.yaml', '_generated.yaml')
    
    updated_config = original_config.dup
    updated_config['cards'] = cards
    updated_config['ai_generation']['save_generated'] = false # Prevent recursive generation
    
    File.open(output_file, 'w') do |file|
      file.write(updated_config.to_yaml)
    end
    
    puts "Generated cards saved to: #{output_file}"
  end

  def generate_apkg(output_path:)
    deck = Anki2.new({ name: name, output_path: output_path })

    cards.each do |card|
      deck.add_card(card['front'], card['back'])
    end

    deck.save
  end

  def add_card(front:, back:)
    cards << { 'front' => front, 'back' => back }
  end

  def sync_with_existing_deck(existing_yaml_file)
    return unless File.exist?(existing_yaml_file)
    
    existing_cards = YAML.load_file(existing_yaml_file)
    existing_cards = existing_cards.is_a?(Array) ? existing_cards : existing_cards['cards'] || []
    
    # Simple deduplication based on front text
    existing_fronts = existing_cards.map { |card| card['front'] }
    new_cards = cards.reject { |card| existing_fronts.include?(card['front']) }
    
    self.cards = existing_cards + new_cards
    
    puts "Synced #{new_cards.length} new cards with existing deck"
  end
end
