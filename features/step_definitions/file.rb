Given /^I save the (?:output|response) to file>.+$/ do |filepath|
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
      pattern.each do |pattern, repl_string|
        content.gsub!(pattern, repl_string)
      end
      filenew.write content
    end
  end
  FileUtils.mv("#{file}.test",file)
end
