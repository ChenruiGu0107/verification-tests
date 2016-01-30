Given /^I save the (?:output|response) to file>(.+)$/ do |filepath|
  File.write(File.expand_path(filepath.strip), @result[:response])
end

# This step is used to delete lines from file. If multiline match is needed,
#   then write another step. If pattern starts with '/' or '%r{' treat as RE.
#   Relative paths are considered inside workdir.
Given /^I delete matching lines from "(.+)":$/ do |file, table|

  # deal with relative file names
  if !file.start_with?("/")
    file = File.join(localhost.workdir, file)
  end

  # put all patterns in an array for efficiency
  patterns = []
  table.raw.flatten.each do |pattern|
    if pattern.start_with?('/') && pattern.end_with?('/')
      patterns << Regexp.new(pattern[1..-2])
    elsif pattern.start_with?('%r{') && pattern.end_with?('}')
      patterns << Regexp.new(pattern[3..-2])
    else
      patterns << pattern
    end
  end

  # use copy to keep the same execution permission
  FileUtils.cp(file,"#{file}.test")
  # delete the lines from the file
  File.open("#{file}.test","w") do |filenew|
    File.foreach(file) do |line|
      filenew.puts line unless patterns.find {|p| line.index(p)}
    end
  end

  FileUtils.mv("#{file}.test",file)
end

# This step is used to replace strings and patterns in file. If pattern starts
#   with '/' or '%r{' treat as RE. Relative paths are considered inside workdir.
Given /^I replace (lines|content) in "(.+)":$/ do |mode, file, table|

  # deal with relative file names
  if !file.start_with?("/")
    file = File.join(localhost.workdir, file)
  end

  # put all the patterns and replacements to the array for efficient
  patterns = []
  patterns = table.raw.map do |pattern, replacement|
    if pattern.start_with?('/') && pattern.end_with?('/')
      [Regexp.new(pattern[1..-2]), replacement]
    elsif pattern.start_with?('%r{') && pattern.end_with?('}')
      [Regexp.new(pattern[3..-2]), replacement]
    else
      [pattern, replacement]
    end
  end

  # use copy to keep the same execution permission
  FileUtils.cp(file,"#{file}.test")
  # replace lines
  File.open("#{file}.test","w") do |filenew|
    if mode == "lines"
      File.foreach(file) do |line|
        # replace the old string with new string
        patterns.each do |pattern, repl_string|
          line.gsub!(pattern, repl_string)
        end
        filenew.puts line
      end
    elsif mode == "content"
      content = File.read(file)
      patterns.each do |pattern, repl_string|
        content.gsub!(pattern, repl_string)
      end
      filenew.write content
    end
  end
  FileUtils.mv("#{file}.test",file)
end

# author gusun@redhat.com
# Note This step is used to restore the modified file
# Usage
#
#    Given I backup the "/home/gusun/test/file" file
#
Given(/^I backup the file>(.+)$/) do |file|
  file.strip!
  filename = File.basename(file)

  if File.exist?("#{filename}.bak")
    raise "Backup already exists."
  else
    FileUtils.cp(file,"#{filename}.bak")
  end
end

# author gusun@redhat.com
# Note This step is used to restore the modified file
# Usage
#
#    Given I restore the "/home/gusun/test/file" file
#
Given /^I restore the file>(.+)$/ do |file|
  file.strip!
  filename = File.basename(file)

  if !File.exist?("#{filename}.bak")
    raise "There is no #{filename}.bak backup."
  else
    FileUtils.rm(file) if File.exist?(file)
    FileUtils.mv("./#{filename}.bak",file)
  end
end

# @param [String] path Path to the file
# @param [Table] table Contents of the file
# @note Creates a local file with the given content
Given /^(?:a|the) "([^"]+)" file is (created|appended) with the following lines:$/ do |path, action, table|
  mode = "w" if action =~ /created/
  mode = "a" if action =~ /appended/
  FileUtils::mkdir_p File.expand_path(File::dirname(path))
  File.open(File.expand_path(path), mode) { |f|
    if table.respond_to? :raw
      table.raw.each do |row|
        f.write("#{row[0]}\n")
      end
    else
      f.write(table)
    end
  }
end
