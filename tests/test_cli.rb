# frozen_string_literal: true

require 'minitest/autorun'
require 'thor'
require 'yaml'
require_relative '../lib/anki_cli'

class AnkiCLITest < Minitest::Test
  def setup
    @temp_yaml = 'temp_cli_test.yaml'
    @temp_apkg = 'temp_cli_test.apkg'
  end

  def teardown
    [@temp_yaml, @temp_apkg].each do |file|
      File.delete(file) if File.exist?(file)
    end
    
    # Clean up any temp files created by CLI
    Dir.glob('temp_*.yaml').each { |f| File.delete(f) }
  end

  def test_create_ai_template_command
    # Test the create_ai_template command
    cli = AnkiCLI.new
    
    # Capture output
    output = capture_io do
      cli.create_ai_template(@temp_yaml)
    end
    
    assert File.exist?(@temp_yaml), 'Template file should be created'
    
    # Verify the template content
    content = YAML.load_file(@temp_yaml)
    assert content.key?('ai_generation'), 'Should have ai_generation section'
    assert content.key?('cards'), 'Should have cards section'
    assert_equal 'medium', content['ai_generation']['difficulty']
    assert_equal 5, content['ai_generation']['count']
    
    assert_match(/AI generation template created/, output[0])
  end

  def test_generate_command_with_traditional_yaml
    # Create a simple YAML file
    cards = [
      { 'front' => 'Test question', 'back' => 'Test answer' }
    ]
    
    File.open(@temp_yaml, 'w') do |file|
      file.write(cards.to_yaml)
    end
    
    cli = AnkiCLI.new
    
    # Test generate command
    output = capture_io do
      cli.generate('Test Deck', @temp_yaml, @temp_apkg)
    end
    
    assert File.exist?(@temp_apkg), 'APKG file should be created'
    assert_match(/successfully created/, output[0])
    assert_match(/Total cards: 1/, output[0])
  end

  def test_cli_help_commands
    # Test that all expected commands are available
    cli = AnkiCLI.new
    commands = cli.class.commands.keys
    
    expected_commands = %w[generate generate_yaml prompt_to_deck create_ai_template test_api]
    expected_commands.each do |cmd|
      assert commands.include?(cmd), "Command #{cmd} should be available"
    end
  end

  def test_generate_yaml_command_structure
    # Test that the generate_yaml command has the right structure
    cli = AnkiCLI.new
    command = cli.class.commands['generate_yaml']
    
    refute_nil command, 'generate_yaml command should exist'
    assert_match(/PROMPT OUTPUT_YAML/, command.usage, 'Should have PROMPT and OUTPUT_YAML arguments')
    
    # Check options (stored as symbols with underscores)
    option_names = command.options.keys
    expected_options = [:api_key, :model, :difficulty, :count, :context, :attach, :prompt_file]
    expected_options.each do |opt|
      assert option_names.include?(opt), "Should have #{opt} option"
    end
  end

  def test_prompt_to_deck_command_structure
    # Test that the prompt_to_deck command has the right structure
    cli = AnkiCLI.new
    command = cli.class.commands['prompt_to_deck']
    
    refute_nil command, 'prompt_to_deck command should exist'
    assert_match(/PROMPT DECK_NAME OUTPUT_FILE/, command.usage, 'Should have PROMPT, DECK_NAME, and OUTPUT_FILE arguments')
    
    # Check options (stored as symbols with underscores)
    option_names = command.options.keys
    expected_options = [:api_key, :model, :difficulty, :count, :context, :save_yaml, :attach, :prompt_file]
    expected_options.each do |opt|
      assert option_names.include?(opt), "Should have #{opt} option"
    end
  end

  def test_command_default_options
    cli = AnkiCLI.new
    
    # Test generate_yaml defaults
    generate_yaml_cmd = cli.class.commands['generate_yaml']
    model_option = generate_yaml_cmd.options[:model]
    difficulty_option = generate_yaml_cmd.options[:difficulty]
    count_option = generate_yaml_cmd.options[:count]
    
    assert_equal 'openai/gpt-3.5-turbo', model_option.default if model_option
    assert_equal 'medium', difficulty_option.default if difficulty_option
    assert_equal 10, count_option.default if count_option
    
    # Test prompt_to_deck defaults
    prompt_to_deck_cmd = cli.class.commands['prompt_to_deck']
    model_option2 = prompt_to_deck_cmd.options[:model]
    difficulty_option2 = prompt_to_deck_cmd.options[:difficulty]
    count_option2 = prompt_to_deck_cmd.options[:count]
    save_yaml_option = prompt_to_deck_cmd.options[:save_yaml]
    
    assert_equal 'openai/gpt-3.5-turbo', model_option2.default if model_option2
    assert_equal 'medium', difficulty_option2.default if difficulty_option2
    assert_equal 10, count_option2.default if count_option2
    assert_equal false, save_yaml_option.default if save_yaml_option
  end

  private

  def capture_io
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    
    yield
    
    [$stdout.string, $stderr.string]
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end
  def test_attachment_options_exist
    # Test that attachment options are properly defined
    cli = AnkiCLI.new
    
    generate_yaml_cmd = cli.class.commands['generate_yaml']
    prompt_to_deck_cmd = cli.class.commands['prompt_to_deck']
    
    # Check attach option
    attach_option_gy = generate_yaml_cmd.options[:attach]
    attach_option_ptd = prompt_to_deck_cmd.options[:attach]
    
    refute_nil attach_option_gy, 'generate_yaml should have attach option'
    refute_nil attach_option_ptd, 'prompt_to_deck should have attach option'
    
    assert_equal :array, attach_option_gy.type, 'attach option should be array type'
    assert_equal :array, attach_option_ptd.type, 'attach option should be array type'
    
    # Check prompt_file option
    prompt_file_option_gy = generate_yaml_cmd.options[:prompt_file]
    prompt_file_option_ptd = prompt_to_deck_cmd.options[:prompt_file]
    
    refute_nil prompt_file_option_gy, 'generate_yaml should have prompt_file option'
    refute_nil prompt_file_option_ptd, 'prompt_to_deck should have prompt_file option'
    
    assert_equal :boolean, prompt_file_option_gy.type, 'prompt_file option should be boolean type'
    assert_equal :boolean, prompt_file_option_ptd.type, 'prompt_file option should be boolean type'
    assert_equal false, prompt_file_option_gy.default, 'prompt_file should default to false'
    assert_equal false, prompt_file_option_ptd.default, 'prompt_file should default to false'
  end

  def test_file_processor_integration
    # Test that FileProcessor is properly required and available
    require_relative '../lib/file_processor'
    
    # Test basic functionality
    temp_file = 'temp_test_content.txt'
    File.write(temp_file, 'Test content for attachment')
    
    begin
      attachments = FileProcessor.process_attachments([temp_file])
      assert_equal 1, attachments.length
      assert_equal 'temp_test_content.txt', attachments.first[:filename]
      assert_equal 'Test content for attachment', attachments.first[:content]
    ensure
      File.delete(temp_file) if File.exist?(temp_file)
    end
  end

  def test_prompt_file_reading
    # Test prompt file reading functionality
    temp_prompt_file = 'temp_prompt.txt'
    prompt_content = 'This is a test prompt from file'
    
    File.write(temp_prompt_file, prompt_content)
    
    begin
      result = FileProcessor.read_prompt_from_file(temp_prompt_file)
      assert_equal prompt_content, result
    ensure
      File.delete(temp_prompt_file) if File.exist?(temp_prompt_file)
    end
  end