# steps for running docker related commands in the master/node

Given /^I store the token from whoami to#{OPT_SYM} clipboard$/ do | cb_name |
  cb_name = :token unless cb_name
  step %Q/I run the :whoami client command with:/, table(%{
    | -t | true |
       })
  if @result[:success]
    cb[cb_name] = @result[:response].strip
  end
end

# extract and save the image digest into a clipboard.  prereq is the output contains the diget output
Given /^I save the docker image digest from output to#{OPT_SYM} clipboard$/ do | cb_name |
  cb_name = :img_digest unless cb_name
  regex = /Digest:\s+(.*)/
  cb[cb_name] = @result[:response].match(regex)[1].strip
end