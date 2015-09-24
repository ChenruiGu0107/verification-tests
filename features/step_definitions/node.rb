Given /^admin get node list$/ do
  @result = CucuShift::Node.list(user: admin)
  @nodes = @result
end

Given /^the first node (name|label) is stored in the(?: :(.*?))? clipboard$/ do |field_name, clipboard_name|
  if @nodes.size == 0
    @result = CucuShift::Node.list(user: admin)
    @nodes = @result
  end
  case field_name
  when "name"
    cb[clipboard_name] = @nodes[0].name
  when "label"
      first_label = ''
      @nodes[0].props[:labels].each do |key,value|
        first_label = key + "=" + value
        break
      end
      cb[clipboard_name] = first_label
  else
    raise "unknown field: #{field_name}"
  end
end
