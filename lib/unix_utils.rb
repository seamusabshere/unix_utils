require 'fileutils'
require 'tmpdir'
require 'uri'
require 'open3'

require "unix_utils/version"

module UnixUtils

  def self.curl(url, form_data = nil)
    outfile = tmp_path url
    if url.start_with?('/') or url.start_with?('file://')
      # deal with local files
      ::FileUtils.cp url.sub('file://', ''), path
      return outfile
    end
    uri = ::URI.parse url
    argv = [ 'curl', '--location', '--show-error', '--silent', '--compressed', '--header', 'Expect: ' ]
    if form_data
      argv += [ '--data', form_data ]
    end
    argv += [ uri.to_s, '--output', outfile ]
    spawn *argv
    outfile
  end

  def self.sha256(infile)
    stdout = spawn 'shasum', '-a', '256', :stdin => infile
    stdout.chomp.split(/\s+/).first
  end
  
  def self.du(srcdir)
    stdout = spawn 'du', srcdir
    stdout.chomp.split(/\s+/).first.to_i
  end

  # --
  
  def self.unzip(infile)
    destdir = tmp_path infile
    ::FileUtils.mkdir destdir
    spawn 'unzip', '-qq', '-n', infile, '-d', destdir
    destdir
  end

  def self.untar(infile)
    destdir = tmp_path infile
    ::FileUtils.mkdir destdir
    spawn 'tar', '-xf', infile, '-C', destdir
    destdir
  end

  def self.gunzip(infile)
    outfile = tmp_path infile
    spawn 'gunzip', '--stdout', infile, :stdout => outfile
    outfile
  end

  def self.bunzip2(infile)
    outfile = tmp_path infile
    spawn 'bunzip2', '--stdout', infile, :stdout => outfile
    outfile
  end

  # --

  def self.bzip2(infile)
    outfile = tmp_path infile
    spawn 'bzip2', '--keep', '--stdout', infile, :stdout => outfile
    outfile
  end
  
  def self.tar(srcdir)
    outfile = tmp_path srcdir
    spawn 'tar', '-cf', outfile, '-C', srcdir, '.'
    outfile
  end

  def self.zip(srcdir)
    outfile = tmp_path srcdir, 'zip'
    spawn 'zip', '-rq', outfile, '.', :chdir => srcdir
    outfile
  end
  
  def self.gzip(infile)
    outfile = tmp_path infile
    spawn 'gzip', '--stdout', infile, :stdout => outfile
    outfile
  end
  #
  # # use awk to convert [CR]LF to CRLF
  # def self.unix2dos(path)
  #   outfile = tmp_path
  #   ::File.open(outfile, 'wb') do |out|
  # see also the simpler version
  #     pid = ::POSIX::Spawn.spawn 'awk', '{ sub(/\r?$/,"\r"); print }', path, :out => out
  #     ::Process.waitpid pid
  #   end
  #   ::FileUtils.mv outfile, path
  #   path
  # end


  #
  #
  #
  #
  # 'wc', '-l', infile).split(/\s+/)[0].try :to_i
  #
  # sha1sum
  # bang('sha1sum', infile)[0..39]
  #
  #
  # def self.in_place(*args)
  #   options = args.extract_options!
  #   infile = args.shift
  #   argv = args
  #   outfile = tmp_path infile
  #   ::File.open(infile, 'r') do |f0|
  #     ::File.open(outfile, 'wb') do |f1|
  #       spawn *argv, :in => f0, :out => f1
  #     end
  #   end
  #   ::FileUtils.mv outfile, infile
  #   nil
  # rescue SpawnError => e
  #   if options[:ignore_error]
  #     $stderr.puts "#{e.inspect} (ignoring error...)"
  #     ::FileUtils.mv outfile, infile
  #   else
  #     raise e
  #   end
  # end
  #  #
  #  #
  # gsed "s/#{quoted_clone_name.gsub('`', %{\\\\`})}/#{resource_model.quoted_table_name.gsub('`', %{\\\\`})}/g" --in-place="" #{p}}
  #
  # # use awk to convert [CR]LF to CRLF
  # def self.unix2dos(infile)
  #   in_place 'awk', '{ sub(/\r?$/,"\r"); print }', infile
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

    raise "not yet supported" if options[:stdin] and options[:stdout]

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
