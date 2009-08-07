class FormDataRetriever
  def initialize(name)
    @name = name
  end

  def retrieve
    return if ENV['RAILS_ENV'] == 'test'

    remote_host = CMSConfig[:form_data_transfer][:remote_host]
    remote_user = CMSConfig[:form_data_transfer][:remote_user]
    command = CMSConfig[:form_data_transfer][:command]
    gpg_homedir = CMSConfig[:form_data_transfer][:gpg_homedir]
    conf = CMSConfig[:form_data_transfer][@name]
    identity = conf[:identity]
    data_dir = conf[:data_dir]
    cmd = "ssh -i #{identity} #{remote_user}@#{remote_host} #{command} #{data_dir}"
    IO.popen(cmd, "r+") do |f|
      while line = f.gets
        n = line.slice(/\ADATA (\d+)/, 1)
        break unless n
        s = f.read(n.to_i)
        stdin_r, stdin_w = IO.pipe
        stdout_r, stdout_w = IO.pipe
        pid = fork {
          stdin_w.close
          STDIN.reopen(stdin_r)
          stdout_r.close
          STDOUT.reopen(stdout_w)
          exec("gpg", "-q", "--homedir", gpg_homedir, "--decrypt")
        }
        stdin_r.close
        stdout_w.close
        stdin_w.print(s)
        stdin_w.close
        data = YAML.load(stdout_r)
        stdout_r.close
        yield(data)
        f.print("OK\n")
      end
    end
  end
end
