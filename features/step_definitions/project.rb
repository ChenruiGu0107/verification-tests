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
    @result[:success] = @result[:project].wait_to_be_created(user)
    unless @result[:success]
      logger.warn("Project #{@result[:project].name} not visible on server after delete")
    end
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
  if @result[:success]
    @result[:success] = p.wait_to_be_deleted(user)
    unless @result[:success]
      logger.warn("Project #{p.name} still visible on server after delete")
    end
  end
end

Given /^the(?: "(.+?)")? project is deleted$/ do |project_name|
  project_name = ' "' + project_name + '"' if project_name
  step "I delete the#{project_name} project"
  unless @result[:success]
    logger.error(@result[:response])
    raise "unable to delete project, see log"
  end
end

When(/^I delete all resources by labels:$/) do |table|
  @result = project.delete_all_labeled(*table.raw.flatten, by: user)
end

Then(/^the project should be empty$/) do
  @result = project.empty?(user: user)
  unless @result[:success]
    logger.error(@result[:response])
    raise "project not empty, see logs"
  end
end
