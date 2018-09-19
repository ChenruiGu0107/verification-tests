# steps for doing git operations
require 'git'
require 'uri'

# @param [String] repo_url git repo that we want to clone from
# @param [String] dir_path Directory path
# @note Clones the remote repository
When /^I git clone the repo #{QUOTED}(?: to #{QUOTED})?$/ do |repo_url, dir_path|
  git = CucuShift::Git.new(uri: repo_url, dir: dir_path)
  git.clone
end

Given /^I git clone the repo #{QUOTED} to #{QUOTED} in the#{OPT_QUOTED} pod$/ do |repo_url, dir_path, pod_name|
  # make sure we are in the correct pod context
  pod = pod(pod_name)
  @result = pod(pod_name).exec("bash", "-c", "mkdir -p #{dir_path} && cd #{dir_path} && git clone #{repo_url}", as: user)
  raise "cannot clone repo" unless @result[:success]
end

# @param [String] repo_url git repo that we want to clone from
# @param [Boolean] if set, then we get git information from local repo,
# @note the commit id is saved to cb[:latest_commit_id]
And /^I get the latest git commit id from repo "([^"]+)"$/ do | spec |
  if spec.include? "://" or spec.include? "@"
    uri = spec
    dir = nil
  else
    uri = nil
    dir = spec
  end
  git = CucuShift::Git.new(uri: uri, dir: dir)
  cb[:git_commit_id] = git.get_latest_commit_id
end
# @param [String] repo_url git repo that we want to commit
# @param [String] message commit message that we add to commit
# @note  Add a commit with a message to the repo
When /^I commit all changes in repo "([^"]*)" with message "([^"]+)"$/ do | spec,message |
  if spec.include? "://" or spec.include? "@"
    raise "don't support remote git repo"
  else
    uri = nil
    dir = spec
  end
  git = CucuShift::Git.new(uri: uri, dir: dir)
  git.add(files:nil, :all => true)
  git.commit(:msg => message)
end

Given /^I remove the remote repository "([^"]*)" from the "([^"]+)" repo$/ do |remote, spec|
  if spec.include? "://" or spec.include? "@"
    raise "invalid remote repo name, please specify remote repo name, not url"
  else
    uri = nil
    dir = spec
  end
  git = CucuShift::Git.new(uri: uri, dir: dir)
  git.remove_remote(remote)
end

Given /^I set local git global config with:$/ do |table|
  git = CucuShift::Git.new(uri: "http://dummy.example.com")
  git.set_global_config(opts_array_to_hash(table, sym_mode: false))

  annotation = "restore global git config for current user on localhost"
  unless teardown_find_annotated annotation
    file = File.join(ENV["HOME"], ".gitconfig")
    orig_host = @host
    @host = Host.localhost
    step "the \"#{file}\" file is restored on host after scenario"
    teardown_annotate_last annotation
    @host = orig_host
  end
end
