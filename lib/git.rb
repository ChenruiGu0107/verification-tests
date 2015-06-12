module CucuShift
  # let you operate a git repo
  class Git
    include Common::Helper

    attr_reader :host, :user

    # @param [String] uri remote git uri; when nil, checking the `origin` remote
    # @param [String] dir base directory of git repo;
    #   might be a relative to workdir or absolute path on host
    # @param [CucuShift::Host] host the host repo is to be located
    # @param [String] user the host os user to run git as; usage is discouraged
    def initialize(uri: nil, dir: nil, host: nil, user: nil)
      @url = url
      @dir = dir
      @host = host || Host.localhost
      @user = user

      raise "need uri or dir" unless url || dir
    end

    def dir
      @dir ||= File.basename(uri).gsub(/\.git$/,"")
    end

    def uri
      @uri if @uri

      res = exec_as("git remote -v")
      uri = res[:response].scan(/origin\s(.+)\s+\(fetch\)$/)[0][0]

      unless @uri
        logger(res[:response])
        raise "cannot find out repo uri"
      end

      return @uri = uri
    end

    # execute commands in repo
    def exec(*cmd)
      unless @cloned
        # if dir exist, then we assume repo is cloned, otherwise clone it now
        unless host.file_exist?(dir)
          clone
        end
        @cloned = true
      end

      host.exec_as(user, "cd '#{dir}'", *cmd)

      unless res[:success]
        logger(res[:response])
        raise "failed to execute command in git repo"
      end

      return res
    end

    # clone a git repo
    def clone
      exec("git clone #{host.shell_escape url} #{host.shell_escape dir}")
    end

    TODO
  end
end
