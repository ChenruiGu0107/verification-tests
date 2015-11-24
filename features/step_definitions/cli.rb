## Put here steps that are mostly cli specific, e.g new-app

# there is no such thing as app in OpenShift but there is a command new-app
#   in the cli that logically represents an app - creating/deploying different
#   pods, services, etc.; There is a discussion coing on to rename and refactor
#   the funcitonality. Not sure that goes anywhere but we could adapt this
#   step for backward compatibility if needed.
Given /^I create a new application with:$/ do |table|
  step 'I run the :new_app client command with:', table
end

# instead of writing multiple steps, this step does this in one go:
# 1. download file from URL
# 2. load it as an ERB file with the cucumber scenario variables binding
# 3. runs `oc create` command over the resulting file
When /^I run oc create( as admin)? over ERB URL: #{HTTP_URL}$/ do |admin, url|
  step %Q|I download a file from "#{url}"|

  # overwrite with ERB loaded content
  loaded = ERB.new(File.read(@result[:abs_path])).result binding
  File.write(@result[:abs_path], loaded)

  if admin
    ensure_admin_tagged
    @result = self.admin.cli_exec(:create, {f: @result[:abs_path]})
  else
    @result = user.cli_exec(:create, {f: @result[:abs_path]})
  end
end

#@param file
#@notes Given a remote (http/s) or local file, run the 'oc process'
#command followed by the 'oc create' command to save space
Given /^I process and create: (.+)$/ do |file|
  begin
    #Run the process command, then pass it in as stdin to 'oc create'
    processed_result = user.cli_exec(:process, {f: file})
    if processed_result[:success]
      @result = user.cli_exec(:create, {f: "-", _stdin: processed_result[:stdout]})
    else
      raise "Unable to process the file."
    end
  rescue
    raise "Cannot open file for processing and/or creating."
  end
end
