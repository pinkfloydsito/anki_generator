# frozen_string_literal: true

require 'faraday'
require 'json'
require 'dotenv/load'

# OpenRouterClient -> API client for OpenRouter
class OpenRouterClient
  BASE_URL = 'https://openrouter.ai/api/v1'
  
  attr_reader :api_key, :model

  def initialize(api_key: nil, model: 'openai/gpt-3.5-turbo')
    @api_key = api_key || ENV['OPENROUTER_API_KEY']
    @model = model
    
    raise ArgumentError, 'API key is required' if @api_key.nil? || @api_key.empty?
  end

  def generate_flashcard(topic:, context: nil, difficulty: 'medium', attachments: nil)
    prompt = build_flashcard_prompt(topic: topic, context: context, difficulty: difficulty, attachments: attachments)
    
    response = make_request(prompt)
    parse_flashcard_response(response)
  end

  def generate_multiple_flashcards(topics:, context: nil, difficulty: 'medium', count: 5, attachments: nil)
    prompt = build_multiple_flashcards_prompt(
      topics: topics, 
      context: context, 
      difficulty: difficulty, 
      count: count,
      attachments: attachments
    )
    
    response = make_request(prompt)
    parse_multiple_flashcards_response(response)
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |conn|
      conn.request :json
      conn.response :json
      conn.adapter Faraday.default_adapter
      conn.headers['Authorization'] = "Bearer #{@api_key}"
      conn.headers['Content-Type'] = 'application/json'
    end
  end

  def make_request(prompt)
    response = connection.post('/chat/completions') do |req|
      req.body = {
        model: @model,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7,
        max_tokens: 1000
      }
    end

    handle_response(response)
  end

  def handle_response(response)
    unless response.success?
      raise "OpenRouter API error: #{response.status} - #{response.body}"
    end

    response.body.dig('choices', 0, 'message', 'content')
  end

  def build_flashcard_prompt(topic:, context:, difficulty:, attachments:)
    base_prompt = <<~PROMPT
      Create a single flashcard for the topic: "#{topic}"
      Difficulty level: #{difficulty}
      #{context ? "Additional context: #{context}" : ''}
      
      #{build_attachments_section(attachments) if attachments}
      
      Format your response as JSON with exactly this structure:
      {
        "front": "Question or prompt",
        "back": "Answer or explanation"
      }
      
      Make the flashcard educational and appropriate for the #{difficulty} difficulty level.
      For the back side, provide a clear, concise explanation.
      #{attachments ? "Use the provided file content to create more accurate and detailed flashcards." : ""}
    PROMPT

    base_prompt.strip
  end

  def build_multiple_flashcards_prompt(topics:, context:, difficulty:, count:, attachments:)
    topics_list = topics.is_a?(Array) ? topics.join(', ') : topics.to_s
    
    base_prompt = <<~PROMPT
      Create #{count} flashcards covering these topics: #{topics_list}
      Difficulty level: #{difficulty}
      #{context ? "Additional context: #{context}" : ''}
      
      #{build_attachments_section(attachments) if attachments}
      
      Format your response as JSON with exactly this structure:
      [
        {
          "front": "Question or prompt 1",
          "back": "Answer or explanation 1"
        },
        {
          "front": "Question or prompt 2", 
          "back": "Answer or explanation 2"
        }
      ]
      
      Make the flashcards educational, diverse, and appropriate for the #{difficulty} difficulty level.
      Ensure each flashcard covers different aspects of the topics.
      #{attachments ? "Use the provided file content to create more accurate and detailed flashcards based on the specific information in the files." : ""}
    PROMPT

    base_prompt.strip
  end

  def parse_flashcard_response(response)
    JSON.parse(response)
  rescue JSON::ParserError => e
    raise "Failed to parse OpenRouter response as JSON: #{e.message}"
  end

  def parse_multiple_flashcards_response(response)
    parsed = JSON.parse(response)
    
    # Ensure we return an array
    parsed.is_a?(Array) ? parsed : [parsed]
  rescue JSON::ParserError => e
    raise "Failed to parse OpenRouter response as JSON: #{e.message}"
  end

  def build_attachments_section(attachments)
    return "" unless attachments && !attachments.empty?
    
    section = "=== ATTACHED FILE CONTENT ===\n\n"
    
    attachments.each do |attachment|
      section += "--- #{attachment[:filename]} ---\n"
      section += "#{attachment[:content]}\n\n"
    end
    
    section += "=== END ATTACHED CONTENT ===\n"
    section
  end
end