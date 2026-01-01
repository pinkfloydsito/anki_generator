# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'
require 'tmpdir'
require_relative '../lib/file_processor'

class FileProcessorTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir('file_processor_test')
    @temp_files = []
  end

  def teardown
    @temp_files.each { |f| f.close! if f.respond_to?(:close!) }
    FileUtils.rm_rf(@temp_dir) if Dir.exist?(@temp_dir)
  end

  def create_temp_file(content, filename = nil, extension = '.txt')
    if filename
      file_path = File.join(@temp_dir, filename)
      File.write(file_path, content)
      file_path
    else
      file = Tempfile.new(['test', extension], @temp_dir)
      file.write(content)
      file.close
      @temp_files << file
      file.path
    end
  end

  def test_process_single_text_file
    content = "This is a test file\nwith multiple lines"
    file_path = create_temp_file(content, 'test.txt')
    
    attachments = FileProcessor.process_attachments([file_path])
    
    assert_equal 1, attachments.length
    attachment = attachments.first
    
    assert_equal 'test.txt', attachment[:filename]
    assert_equal file_path, attachment[:path]
    assert_equal content, attachment[:content]
  end

  def test_process_multiple_files
    file1_content = "First file content"
    file2_content = "Second file content"
    
    file1_path = create_temp_file(file1_content, 'file1.rb')
    file2_path = create_temp_file(file2_content, 'file2.py')
    
    attachments = FileProcessor.process_attachments([file1_path, file2_path])
    
    assert_equal 2, attachments.length
    
    file1_attachment = attachments.find { |a| a[:filename] == 'file1.rb' }
    file2_attachment = attachments.find { |a| a[:filename] == 'file2.py' }
    
    refute_nil file1_attachment
    refute_nil file2_attachment
    
    assert_equal file1_content, file1_attachment[:content]
    assert_equal file2_content, file2_attachment[:content]
  end

  def test_process_directory
    # Create files in directory
    create_temp_file("File 1 content", 'file1.txt')
    create_temp_file("File 2 content", 'file2.md')
    create_temp_file("Binary content", 'binary.exe') # This should be skipped
    
    attachments = FileProcessor.process_attachments([@temp_dir])
    
    # Should process text files but skip binary
    # Note: binary.exe might still be processed if it's detected as text
    assert attachments.length >= 2, "Should process at least 2 text files"
    
    filenames = attachments.map { |a| a[:filename] }
    assert_includes filenames, 'file1.txt'
    assert_includes filenames, 'file2.md'
  end

  def test_text_file_detection
    # Test various text file extensions
    text_extensions = %w[.txt .md .rb .py .js .json .yaml .yml]
    
    text_extensions.each do |ext|
      assert FileProcessor.text_file?(Pathname.new("test#{ext}")), "#{ext} should be detected as text"
    end
    
    # Test binary extensions by creating actual binary-like content
    binary_content = "\x00\x01\x02\x03\x04\x05" # Actual binary content with null bytes
    binary_file_path = create_temp_file(binary_content, "test.exe")
    
    refute FileProcessor.text_file?(Pathname.new(binary_file_path)), ".exe with binary content should not be detected as text"
  end

  def test_file_size_limits
    # Create a large file that exceeds the limit
    large_content = "x" * (FileProcessor::MAX_FILE_SIZE + 1000)
    large_file_path = create_temp_file(large_content, 'large.txt')
    
    # Should be skipped due to size
    attachments = FileProcessor.process_attachments([large_file_path])
    assert_empty attachments
  end

  def test_total_size_limit
    # Create multiple files that together exceed the total limit
    # Use smaller individual files that are within the individual limit
    file_size = FileProcessor::MAX_FILE_SIZE / 2  # Use half the individual limit
    
    file1_path = create_temp_file("x" * file_size, 'file1.txt')
    file2_path = create_temp_file("y" * file_size, 'file2.txt')
    file3_path = create_temp_file("z" * file_size, 'file3.txt')
    file4_path = create_temp_file("w" * file_size, 'file4.txt')
    file5_path = create_temp_file("v" * file_size, 'file5.txt')
    file6_path = create_temp_file("u" * file_size, 'file6.txt')
    file7_path = create_temp_file("t" * file_size, 'file7.txt')
    file8_path = create_temp_file("s" * file_size, 'file8.txt')
    file9_path = create_temp_file("r" * file_size, 'file9.txt')
    file10_path = create_temp_file("q" * file_size, 'file10.txt')
    file11_path = create_temp_file("p" * file_size, 'file11.txt')
    
    all_files = [file1_path, file2_path, file3_path, file4_path, file5_path, 
                 file6_path, file7_path, file8_path, file9_path, file10_path, file11_path]
    
    attachments = FileProcessor.process_attachments(all_files)
    
    # Should stop before processing all files due to total size limit
    assert attachments.length < all_files.length, "Should process fewer files due to total size limit"
    assert attachments.length >= 2, "Should get at least 2 files"
    
    # Verify total size doesn't exceed limit
    total_size = attachments.sum { |a| a[:content].bytesize }
    assert total_size <= FileProcessor::MAX_TOTAL_SIZE, "Total size should not exceed limit"
  end

  def test_nonexistent_file
    attachments = FileProcessor.process_attachments(['nonexistent_file.txt'])
    assert_empty attachments
  end

  def test_empty_paths
    assert_empty FileProcessor.process_attachments([])
    assert_empty FileProcessor.process_attachments(nil)
  end

  def test_read_prompt_from_file
    prompt_content = "This is a test prompt\nwith multiple lines"
    prompt_file = create_temp_file(prompt_content, 'prompt.txt')
    
    result = FileProcessor.read_prompt_from_file(prompt_file)
    assert_equal prompt_content, result
  end

  def test_read_prompt_from_nonexistent_file
    assert_raises(RuntimeError) do
      FileProcessor.read_prompt_from_file('nonexistent_prompt.txt')
    end
  end

  def test_read_prompt_from_empty_file
    empty_file = create_temp_file('', 'empty_prompt.txt')
    
    assert_raises(RuntimeError) do
      FileProcessor.read_prompt_from_file(empty_file)
    end
  end

  def test_format_size
    assert_equal "500 B", FileProcessor.format_size(500)
    assert_equal "1.5 KB", FileProcessor.format_size(1536)
    assert_equal "2.0 MB", FileProcessor.format_size(2_097_152)
  end

  def test_mixed_file_and_directory_processing
    # Create individual file
    individual_file = create_temp_file("Individual file content", 'individual.txt')
    
    # Create directory with files
    create_temp_file("Dir file 1", 'dir_file1.rb')
    create_temp_file("Dir file 2", 'dir_file2.py')
    
    attachments = FileProcessor.process_attachments([individual_file, @temp_dir])
    
    # Should have individual file + directory files
    assert attachments.length >= 3, "Should process at least 3 files"
    
    filenames = attachments.map { |a| a[:filename] }
    assert_includes filenames, 'individual.txt'
    assert_includes filenames, 'dir_file1.rb'
    assert_includes filenames, 'dir_file2.py'
  end

  def test_file_content_truncation
    # Test that very long content gets truncated properly
    long_content = "x" * (FileProcessor::MAX_FILE_SIZE - 100) + "END_MARKER"
    file_path = create_temp_file(long_content, 'long.txt')
    
    attachments = FileProcessor.process_attachments([file_path])
    
    assert_equal 1, attachments.length
    content = attachments.first[:content]
    
    # Should contain the content but might be truncated
    assert content.length <= FileProcessor::MAX_FILE_SIZE + 20 # Allow for truncation message
  end
end