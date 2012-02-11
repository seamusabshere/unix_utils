require 'fileutils'
require 'tmpdir'
require 'uri'
require 'open3'

require "unix_utils/version"

module UnixUtils

  def self.curl(url, form_data = nil)
    out_path = tmp_path url
    if url.start_with?('/') or url.start_with?('file://')
      # deal with local files
      ::FileUtils.cp url.sub('file://', ''), path
      return out_path
    end
    uri = ::URI.parse url
    argv = [ 'curl', '--location', '--show-error', '--silent', '--compressed', '--header', 'Expect: ' ]
    if form_data
      argv += [ '--data', form_data ]
    end
    argv += [ uri.to_s, '--output', out_path ]
    spawn *argv
    out_path
  end

  def self.sha256(in_path)
    stdout = spawn 'shasum', '-a', '256', :stdin => in_path
    stdout.chomp.split(/\s+/).first
  end
  
  def self.du(in_dir)
    stdout = spawn 'du', in_dir
    stdout.chomp.split(/\s+/).first.to_i
  end

  # --
  
  def self.unzip(in_path)
    out_dir = tmp_path in_path
    ::FileUtils.mkdir out_dir
    spawn 'unzip', '-qq', '-n', in_path, '-d', out_dir
    out_dir
  end

  def self.untar(in_path)
    out_dir = tmp_path in_path
    ::FileUtils.mkdir out_dir
    spawn 'tar', '-xf', in_path, '-C', out_dir
    out_dir
  end

  def self.gunzip(in_path)
    out_path = tmp_path in_path
    spawn 'gunzip', '--stdout', in_path, :stdout => out_path
    out_path
  end

  def self.bunzip2(in_path)
    out_path = tmp_path in_path
    spawn 'bunzip2', '--stdout', in_path, :stdout => out_path
    out_path
  end

  # --

  def self.bzip2(in_path)
    out_path = tmp_path in_path
    spawn 'bzip2', '--keep', '--stdout', in_path, :stdout => out_path
    out_path
  end
  
  def self.tar(in_dir)
    out_path = tmp_path in_dir
    spawn 'tar', '-cf', out_path, '-C', in_dir, '.'
    out_path
  end

  def self.zip(in_dir)
    out_path = tmp_path in_dir, 'zip'
    spawn 'zip', '-rq', out_path, '.', :chdir => in_dir
    out_path
  end
  
  def self.gzip(in_path)
    out_path = tmp_path in_path
    spawn 'gzip', '--stdout', in_path, :stdout => out_path
    out_path
  end
  #
  # # use awk to convert [CR]LF to CRLF
  # def self.unix2dos(path)
  #   out_path = tmp_path
  #   ::File.open(out_path, 'wb') do |out|
  # see also the simpler version
  #     pid = ::POSIX::Spawn.spawn 'awk', '{ sub(/\r?$/,"\r"); print }', path, :out => out
  #     ::Process.waitpid pid
  #   end
  #   ::FileUtils.mv out_path, path
  #   path
  # end


  #
  #
  #
  #
  # 'wc', '-l', in_path).split(/\s+/)[0].try :to_i
  #
  # sha1sum
  # bang('sha1sum', in_path)[0..39]
  #
  #
  # def self.in_place(*args)
  #   options = args.extract_options!
  #   in_path = args.shift
  #   argv = args
  #   out_path = tmp_path in_path
  #   ::File.open(in_path, 'r') do |f0|
  #     ::File.open(out_path, 'wb') do |f1|
  #       spawn *argv, :in => f0, :out => f1
  #     end
  #   end
  #   ::FileUtils.mv out_path, in_path
  #   nil
  # rescue SpawnError => e
  #   if options[:ignore_error]
  #     $stderr.puts "#{e.inspect} (ignoring error...)"
  #     ::FileUtils.mv out_path, in_path
  #   else
  #     raise e
  #   end
  # end
  #  #
  #  #
  # gsed "s/#{quoted_clone_name.gsub('`', %{\\\\`})}/#{resource_model.quoted_table_name.gsub('`', %{\\\\`})}/g" --in-place="" #{p}}
  #
  # # use awk to convert [CR]LF to CRLF
  # def self.unix2dos(in_path)
  #   in_place 'awk', '{ sub(/\r?$/,"\r"); print }', in_path
  # end

  # mostly for internal use...

  def self.tmp_path(ancestor, extname = nil)
    basename = ::File.basename ancestor.gsub(/\W+/, '_')
    basename.sub!(/^unix_utils-[0-9]+-/, '')
    if extname
      basename.concat ".#{extname}"
    end
    ::Kernel.srand
    ::File.join ::Dir.tmpdir, "unix_utils-#{::Kernel.rand(1e11)}-#{basename}"
  end

  def self.spawn(*argv)
    argv = argv.dup
    options = argv.last.is_a?(::Hash) ? argv.pop : {}
    
    if options[:chdir]
      old_pwd = ::Dir.pwd
      ::Dir.chdir options[:chdir]
    end
    
    whole_stdout = nil
    whole_stderr = nil

    if options[:stdin]
      ::File.open(options[:stdin], 'r') do |in_f|
        ::Open3.popen3(*argv) do |stdin, stdout, stderr|
          while chunk = in_f.read(4_194_304)
            stdin.write chunk
          end
          stdin.close
          whole_stdout = stdout.read
          whole_stderr = stderr.read
        end
      end
    elsif options[:stdout]
      ::File.open(options[:stdout], 'wb') do |out_f|
        ::Open3.popen3(*argv) do |stdin, stdout, stderr|
          stdin.close
          while chunk = stdout.read(4_194_304)
            out_f.write chunk
          end
          whole_stdout = "Redirected to #{options[:stdout]}"
          whole_stderr = stderr.read
        end
      end
    else
      ::Open3.popen3(*argv) do |stdin, stdout, stderr|
        stdin.close
        whole_stdout = stdout.read
        whole_stderr = stderr.read
      end
    end

    unless whole_stderr.empty?
      $stderr.puts "[unix_utils] `#{argv.join(' ')}` STDERR:"
      $stderr.puts whole_stderr
    end

    whole_stdout

  ensure
    if options[:chdir]
      ::Dir.chdir old_pwd
    end
  end
end
