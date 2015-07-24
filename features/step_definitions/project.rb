Given /^I have a project$/ do
  if @project && @project.visible?(user)
    # do nothing, we're covered
  else
    projects = user.projects
    if projects.empty?
      res = CucuShift::Project.create(by: user, name: rand_str(5).downcase)
      if res[:success]
        @project = res[:project]
      else
        logger.error(res[:response])
        raise "unable to create project, see log"
      end
    else
      @project = projects.first
    end
  end
end

Given /^I delete the(?: "(.+?)")? project$/ do |project|
  if project
    @project = CucuShift::Project.new(env: user.env, name: project)
  end

  raise "project cannot be nil" unless @project

  @result = @project.delete(by: user)
end
