# steps for doing git operations
require 'git'
require 'uri'

# @param [String] repo_url git repo that we want to clone from
# @param [String] dir_path Directory path
# @note Clones the remote repository
When /^I git clone the repo "([^"]+)"(?: to "([^"]+)")?$/ do |repo_url, dir_path|
  git = CucuShift::Git.new(uri:repo_url, dir: dir_path)
  git.clone
end

# @param [String] repo_url git repo that we want to clone from
# @param [Boolean] if set, then we get git information from local repo,
# @note the commit id is saved to @clipboard[:latest_commit_id]
And /^I get the latest git commit id from repo "([^"]+)"$/ do | path |
  locally = false
  uri = dir = nil
  if path.include? "://" or path.include? "@"
    locally = true
   	uri = path
    dir = nil
  else
    uri = @uri
  	dir = path
  end
  git = CucuShift::Git.new(uri:uri, dir:dir)
  @clipboard[:latest_commit_id] = git.get_latest_commit_id(local: locally)
end
