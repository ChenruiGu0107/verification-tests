# ssl related steps

Given /^the #{QUOTED} cert file is parsed into the#{OPT_SYM} clipboard$/ do |cert_path, cb_name |
  cb_name ||= :cert
  cert = OpenSSL::X509::Certificate.new(File.read(File.expand_path(cert_path)))
  cb[cb_name] = cert
end
