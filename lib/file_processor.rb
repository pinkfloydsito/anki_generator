# frozen_string_literal: true

require 'pathname'

# FileProcessor -> Handles file and directory processing for attachments
class FileProcessor
  # Supported text file extensions
  TEXT_EXTENSIONS = %w[.txt .md .rb .py .js .ts .java .cpp .c .h .hpp .css .html .xml .json .yaml .yml .sql .sh .bat .ps1 .php .go .rs .swift .kt .scala .clj .hs .elm .ex .exs .erl .pl .r .m .tex .org .rst .adoc].freeze
  
  # Maximum file size in bytes (1MB)
  MAX_FILE_SIZE = 1_048_576
  
  # Maximum total content size (5MB)
  MAX_TOTAL_SIZE = 5_242_880

  def self.process_attachments(paths)
    return [] if paths.nil? || paths.empty?
    
    attachments = []
    total_size = 0
    
    paths.each do |path_str|
      path = Pathname.new(path_str)
      
      unless path.exist?
        puts "⚠️  Warning: Path does not exist: #{path_str}"
        next
      end
      
      if path.directory?
        dir_attachments = process_directory(path)
        dir_attachments.each do |attachment|
          if total_size + attachment[:content].bytesize > MAX_TOTAL_SIZE
            puts "⚠️  Warning: Total attachment size limit reached. Skipping remaining files."
            break
          end
          attachments << attachment
          total_size += attachment[:content].bytesize
        end
      elsif path.file?
        attachment = process_file(path)
        if attachment
          if total_size + attachment[:content].bytesize > MAX_TOTAL_SIZE
            puts "⚠️  Warning: Total attachment size limit reached. Skipping #{path_str}"
          else
            attachments << attachment
            total_size += attachment[:content].bytesize
          end
        end
      else
        puts "⚠️  Warning: Path is neither file nor directory: #{path_str}"
      end
    end
    
    puts "📎 Processed #{attachments.length} file(s) (#{format_size(total_size)})" if attachments.any?
    attachments
  end

  def self.process_directory(dir_path)
    attachments = []
    
    # Find all text files in directory (non-recursive for now)
    dir_path.children.each do |child|
      next unless child.file?
      
      attachment = process_file(child)
      attachments << attachment if attachment
    end
    
    attachments
  end

  def self.process_file(file_path)
    # Check file size
    if file_path.size > MAX_FILE_SIZE
      puts "⚠️  Warning: File too large, skipping: #{file_path} (#{format_size(file_path.size)})"
      return nil
    end
    
    # Check if it's a text file
    unless text_file?(file_path)
      puts "⚠️  Warning: Non-text file, skipping: #{file_path}"
      return nil
    end
    
    begin
      content = file_path.read(encoding: 'UTF-8')
      
      # Truncate if too long
      if content.bytesize > MAX_FILE_SIZE
        content = content.byteslice(0, MAX_FILE_SIZE) + "\n... [truncated]"
      end
      
      {
        filename: file_path.basename.to_s,
        path: file_path.to_s,
        content: content
      }
    rescue => e
      puts "⚠️  Warning: Could not read file #{file_path}: #{e.message}"
      nil
    end
  end

  def self.text_file?(file_path)
    # Check extension
    ext = file_path.extname.downcase
    return true if TEXT_EXTENSIONS.include?(ext)
    
    # For files without extension, try to detect if it's text
    return false if file_path.extname.empty? && file_path.basename.to_s !~ /^[A-Z_]+$/
    
    # Try to read first few bytes to detect binary files
    begin
      sample = file_path.read(512, encoding: 'BINARY')
      # If it contains null bytes, it's likely binary
      !sample.include?("\x00")
    rescue
      false
    end
  end

  def self.format_size(bytes)
    if bytes < 1024
      "#{bytes} B"
    elsif bytes < 1024 * 1024
      "#{(bytes / 1024.0).round(1)} KB"
    else
      "#{(bytes / (1024.0 * 1024)).round(1)} MB"
    end
  end

  def self.read_prompt_from_file(file_path)
    path = Pathname.new(file_path)
    
    unless path.exist?
      raise "Prompt file does not exist: #{file_path}"
    end
    
    unless path.file?
      raise "Prompt path is not a file: #{file_path}"
    end
    
    begin
      content = path.read(encoding: 'UTF-8').strip
      
      if content.empty?
        raise "Prompt file is empty: #{file_path}"
      end
      
      content
    rescue => e
      raise "Could not read prompt file #{file_path}: #{e.message}"
    end
  end
end