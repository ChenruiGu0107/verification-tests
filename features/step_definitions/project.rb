Given /^I have a project$/ do
  project = @projects.reverse.find {|p| p.visible?(user)}
  if project
    # project does exist as visible is doing an actual query
    # also move project up the stack
    @projects << @projects.delete(project)
  else
    projects = user.projects
    if projects.empty?
      step 'I create a new project'
      unless @result[:success]
        logger.error(@result[:response])
        raise "unable to create project, see log"
      end
    else
      # at this point we know that project cache does not contain any user
      #   visible projects, so we can safely add user projects to cache
      @projects.concat projects
    end
  end
end

# try to create a new project with current user
When /^I create a new project$/ do
  @result = CucuShift::Project.create(by: user, name: rand_str(5, :dns))
  if @result[:success]
    @projects << @result[:project]
    sleep 5 # TODO: need smarter check if change propagated
  end
end

Given /^I use the "(.+?)" project$/ do |project_name|
  # this would find project in cache and move it up the stack
  # or create a new CucuShift::Project object and put it on top of stack
  project(project_name)
end

# tries to delete last used project or a project with given name (if name given)
When /^I delete the(?: "(.+?)")? project$/ do |project_name|
  p = project(project_name)
  @result = project(project_name).delete(by: user)
  @projects.delete(p)
  sleep 5 if @result[:success] # TODO: need smarter check if change propagated
end
