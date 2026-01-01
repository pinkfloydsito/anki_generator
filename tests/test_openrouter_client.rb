# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require_relative '../lib/openrouter_client'

class OpenRouterClientTest < Minitest::Test
  def setup
    @api_key = 'test_api_key'
    @client = OpenRouterClient.new(api_key: @api_key)
  end

  def test_initialization_with_api_key
    client = OpenRouterClient.new(api_key: 'test_key')
    assert_equal 'test_key', client.api_key
    assert_equal 'openai/gpt-3.5-turbo', client.model
  end

  def test_initialization_with_custom_model
    client = OpenRouterClient.new(api_key: 'test_key', model: 'claude-3-sonnet')
    assert_equal 'claude-3-sonnet', client.model
  end

  def test_initialization_without_api_key_raises_error
    ENV.delete('OPENROUTER_API_KEY')
    
    assert_raises(ArgumentError) do
      OpenRouterClient.new
    end
  end

  def test_initialization_with_env_var
    ENV['OPENROUTER_API_KEY'] = 'env_api_key'
    client = OpenRouterClient.new
    assert_equal 'env_api_key', client.api_key
  ensure
    ENV.delete('OPENROUTER_API_KEY')
  end

  def test_generate_flashcard_success
    mock_response = {
      'choices' => [
        {
          'message' => {
            'content' => '{"front": "What is Ruby?", "back": "Ruby is a programming language"}'
          }
        }
      ]
    }

    # Mock the Faraday connection
    mock_connection = Minitest::Mock.new
    mock_faraday_response = Minitest::Mock.new
    
    mock_faraday_response.expect(:success?, true)
    mock_faraday_response.expect(:body, mock_response)
    
    mock_connection.expect(:post, mock_faraday_response, ['/chat/completions'])
    
    @client.stub(:connection, mock_connection) do
      result = @client.generate_flashcard(topic: 'Ruby programming')
      
      assert_equal 'What is Ruby?', result['front']
      assert_equal 'Ruby is a programming language', result['back']
    end

    mock_connection.verify
    mock_faraday_response.verify
  end

  def test_generate_multiple_flashcards_success
    mock_response = {
      'choices' => [
        {
          'message' => {
            'content' => '[{"front": "What is Ruby?", "back": "A programming language"}, {"front": "What is Rails?", "back": "A web framework"}]'
          }
        }
      ]
    }

    mock_connection = Minitest::Mock.new
    mock_faraday_response = Minitest::Mock.new
    
    mock_faraday_response.expect(:success?, true)
    mock_faraday_response.expect(:body, mock_response)
    
    mock_connection.expect(:post, mock_faraday_response, ['/chat/completions'])
    
    @client.stub(:connection, mock_connection) do
      result = @client.generate_multiple_flashcards(topics: ['Ruby', 'Rails'], count: 2)
      
      assert_equal 2, result.length
      assert_equal 'What is Ruby?', result[0]['front']
      assert_equal 'What is Rails?', result[1]['front']
    end

    mock_connection.verify
    mock_faraday_response.verify
  end

  def test_api_error_handling
    mock_connection = Minitest::Mock.new
    mock_faraday_response = Minitest::Mock.new
    
    mock_faraday_response.expect(:success?, false)
    mock_faraday_response.expect(:status, 401)
    mock_faraday_response.expect(:body, { 'error' => 'Unauthorized' })
    
    mock_connection.expect(:post, mock_faraday_response, ['/chat/completions'])
    
    @client.stub(:connection, mock_connection) do
      assert_raises(RuntimeError, /OpenRouter API error: 401/) do
        @client.generate_flashcard(topic: 'Test topic')
      end
    end

    mock_connection.verify
    mock_faraday_response.verify
  end

  def test_json_parse_error_handling
    mock_response = {
      'choices' => [
        {
          'message' => {
            'content' => 'Invalid JSON response'
          }
        }
      ]
    }

    mock_connection = Minitest::Mock.new
    mock_faraday_response = Minitest::Mock.new
    
    mock_faraday_response.expect(:success?, true)
    mock_faraday_response.expect(:body, mock_response)
    
    mock_connection.expect(:post, mock_faraday_response, ['/chat/completions'])
    
    @client.stub(:connection, mock_connection) do
      assert_raises(RuntimeError, /Failed to parse OpenRouter response as JSON/) do
        @client.generate_flashcard(topic: 'Test topic')
      end
    end

    mock_connection.verify
    mock_faraday_response.verify
  end
end
  def test_generate_flashcard_with_attachments
    # Test flashcard generation with file attachments
    attachments = [
      {
        filename: 'test.rb',
        path: '/path/to/test.rb',
        content: 'def hello\n  puts "Hello, World!"\nend'
      },
      {
        filename: 'readme.md',
        path: '/path/to/readme.md', 
        content: '# Test Project\nThis is a test Ruby project.'
      }
    ]
    
    # Mock the HTTP response
    mock_response_body = {
      'choices' => [
        {
          'message' => {
            'content' => '{"front": "What does this Ruby method do?", "back": "It prints Hello, World! to the console"}'
          }
        }
      ]
    }
    
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true
    mock_response.expect :body, mock_response_body
    
    mock_connection = Minitest::Mock.new
    mock_connection.expect :post, mock_response, ['/chat/completions']
    
    @client.stub :connection, mock_connection do
      result = @client.generate_flashcard(
        topic: 'Ruby programming',
        attachments: attachments
      )
      
      assert_equal 'What does this Ruby method do?', result['front']
      assert_equal 'It prints Hello, World! to the console', result['back']
    end
    
    mock_response.verify
    mock_connection.verify
  end

  def test_generate_multiple_flashcards_with_attachments
    # Test multiple flashcard generation with attachments
    attachments = [
      {
        filename: 'algorithm.py',
        path: '/path/to/algorithm.py',
        content: 'def binary_search(arr, target):\n    # Implementation here\n    pass'
      }
    ]
    
    # Mock the HTTP response
    mock_response_body = {
      'choices' => [
        {
          'message' => {
            'content' => '[{"front": "What is binary search?", "back": "A search algorithm"}, {"front": "Time complexity?", "back": "O(log n)"}]'
          }
        }
      ]
    }
    
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true
    mock_response.expect :body, mock_response_body
    
    mock_connection = Minitest::Mock.new
    mock_connection.expect :post, mock_response, ['/chat/completions']
    
    @client.stub :connection, mock_connection do
      result = @client.generate_multiple_flashcards(
        topics: ['Algorithms', 'Data structures'],
        attachments: attachments,
        count: 2
      )
      
      assert_equal 2, result.length
      assert_equal 'What is binary search?', result[0]['front']
      assert_equal 'Time complexity?', result[1]['front']
    end
    
    mock_response.verify
    mock_connection.verify
  end

  def test_build_attachments_section
    attachments = [
      {
        filename: 'test.rb',
        path: '/path/to/test.rb',
        content: 'puts "Hello"'
      },
      {
        filename: 'config.yml',
        path: '/path/to/config.yml',
        content: 'database:\n  host: localhost'
      }
    ]
    
    # Use send to access private method for testing
    result = @client.send(:build_attachments_section, attachments)
    
    assert_includes result, '=== ATTACHED FILE CONTENT ==='
    assert_includes result, '--- test.rb ---'
    assert_includes result, 'puts "Hello"'
    assert_includes result, '--- config.yml ---'
    assert_includes result, 'database:'
    assert_includes result, '=== END ATTACHED CONTENT ==='
  end

  def test_build_attachments_section_empty
    result = @client.send(:build_attachments_section, nil)
    assert_equal "", result
    
    result = @client.send(:build_attachments_section, [])
    assert_equal "", result
  end

  def test_generate_flashcard_with_context_and_attachments
    # Test flashcard generation with both context and attachments
    attachments = [
      {
        filename: 'example.js',
        path: '/path/to/example.js',
        content: 'function fibonacci(n) {\n  return n <= 1 ? n : fibonacci(n-1) + fibonacci(n-2);\n}'
      }
    ]
    
    mock_response_body = {
      'choices' => [
        {
          'message' => {
            'content' => '{"front": "What is the time complexity of this recursive fibonacci?", "back": "O(2^n) - exponential time complexity"}'
          }
        }
      ]
    }
    
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true
    mock_response.expect :body, mock_response_body
    
    mock_connection = Minitest::Mock.new
    mock_connection.expect :post, mock_response, ['/chat/completions']
    
    @client.stub :connection, mock_connection do
      result = @client.generate_flashcard(
        topic: 'Algorithm complexity',
        context: 'Computer science fundamentals',
        difficulty: 'hard',
        attachments: attachments
      )
      
      assert_equal 'What is the time complexity of this recursive fibonacci?', result['front']
      assert_equal 'O(2^n) - exponential time complexity', result['back']
    end
    
    mock_response.verify
    mock_connection.verify
  end