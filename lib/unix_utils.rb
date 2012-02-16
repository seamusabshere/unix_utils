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

  #--
  # most platforms
  # $ openssl dgst -sha256 .bash_profile 
  # SHA256(.bash_profile)= ae12206aaa35dc96273ed421f4e85ca26a1707455e3cc9f054c7f5e2e9c53df6
  # ubuntu 11.04
  # $ shasum -a 256 --portable .mysql_history 
  # 856aa27deb0b80b41031c2ddf722af28ba2a8c4999ff9cf2d45f33bc67d992ba ?.mysql_history
  # fedora 7
  # $ sha256sum --binary .bash_profile 
  # 01b1210962b3d1e5e1ccba26f93d98efbb7b315b463f9f6bdb40ab496728d886 *.bash_profile
  def self.shasum(infile, algorithm)
    if available?('shasum')
      stdout = spawn 'shasum', '--binary', '-a', algorithm.to_s, infile
      stdout.strip.split(' ').first
    else
      stdout = spawn 'openssl', 'dgst', "-sha#{algorithm}", infile
      stdout.strip.split(' ').last
    end
  end
  
  #--
  # os x 10.6.8; most platforms
  # $ openssl dgst -md5 .bashrc 
  # MD5(.bashrc)= 88f464fb6d1d6fe9141135248bf7b265
  # ubuntu 11.04; fedora 7; gentoo
  # $ md5sum --binary .mysql_history 
  # 8d01e54ab8142d6786850e22d55a1b6c *.mysql_history  
  def self.md5sum(infile)
    if available?('md5sum')
      stdout = spawn 'md5sum', '--binary', infile
      stdout.strip.split(' ').first
    else
      stdout = spawn 'openssl', 'dgst', '-md5', infile
      stdout.strip.split(' ').last
    end
  end
    
  def self.du(srcdir)
    stdout = spawn 'du', srcdir
    stdout.strip.split(/\s+/).first.to_i
  end
  
  def self.wc(infile)
    stdout = spawn 'wc', infile
    stdout.strip.split(/\s+/)[0..2].map { |s| s.to_i }
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
    spawn 'gunzip', '--stdout', infile, :write_to => outfile
    outfile
  end

  def self.bunzip2(infile)
    outfile = tmp_path infile
    spawn 'bunzip2', '--stdout', infile, :write_to => outfile
    outfile
  end

  # --

  def self.bzip2(infile)
    outfile = tmp_path infile, '.bz2'
    spawn 'bzip2', '--keep', '--stdout', infile, :write_to => outfile
    outfile
  end
  
  def self.tar(srcdir)
    outfile = tmp_path srcdir, '.tar'
    spawn 'tar', '-cf', outfile, '-C', srcdir, '.'
    outfile
  end

  def self.zip(srcdir)
    outfile = tmp_path srcdir, '.zip'
    spawn 'zip', '-rq', outfile, '.', :chdir => srcdir
    outfile
  end
  
  def self.gzip(infile)
    outfile = tmp_path infile, '.gz'
    spawn 'gzip', '--stdout', infile, :write_to => outfile
    outfile
  end
  
  # --
  
  def self.awk(infile, *expr)
    outfile = tmp_path infile
    bin = available?('gawk') ? 'gawk' : 'awk'
    argv = [ bin, expr, infile ].flatten
    spawn(*argv, :write_to => outfile)
    outfile
  end
  
  # Yes, this is a very limited use of perl.
  def self.perl(infile, *expr)
    outfile = tmp_path infile
    argv = ['perl', expr.map { |e| ['-pe', e] } ].flatten
    spawn(*argv, :read_from => infile, :write_to => outfile)
    outfile
  end
  
  def self.unix2dos(infile)
    if available?('gawk') or available?('awk')
      awk infile, '{ sub(/\r/, ""); printf("%s\r\n", $0) }'
    else
      perl infile, 's/\r\n|\n|\r/\r\n/g'
    end
  end
  
  def self.dos2unix(infile)
    if available?('gawk') or available?('awk')
      awk infile, '{ sub(/\r/, ""); printf("%s\n", $0) }'
    else
      perl infile, 's/\r\n|\n|\r/\n/g'
    end
  end

  def self.sed(infile, *expr)
    outfile = tmp_path infile
    bin = available?('gsed') ? 'gsed' : 'sed'
    argv = [ bin, expr.map { |e| ['-e', e] } ].flatten
    spawn(*argv, :read_from => infile, :write_to => outfile)
    outfile
  end

  def self.tail(infile, lines)
    outfile = tmp_path infile
    spawn 'tail', '-n', lines.to_s, infile, :write_to => outfile
    outfile
  end
  
  def self.head(infile, lines)
    outfile = tmp_path infile
    spawn 'head', '-n', lines.to_s, infile, :write_to => outfile
    outfile
  end

  # specify character_positions as a string like "3-5" or "3,9-10"
  def self.cut(infile, character_positions)
    outfile = tmp_path infile
    spawn 'cut', '-c', character_positions, infile, :write_to => outfile
    outfile
  end

  def self.iconv(infile, to, from)
    outfile = tmp_path infile
    spawn 'iconv', '-t', to, '-f', from, infile, :write_to => outfile
    outfile
  end
  
  def self.available?(bin) # :nodoc:
    bin = bin.to_s
    return @@available_query[bin] if defined?(@@available_query) and @@available_query.is_a?(::Hash) and @@available_query.has_key?(bin)
    @@available_query ||= {}
    @@available_query[bin] = ::Kernel.system 'which', '-s', bin
  end

  def self.tmp_path(ancestor, extname = nil) # :nodoc:
    extname ||= ::File.extname ancestor
    basename = ::File.basename ancestor.sub(/^unix_utils-[0-9]+-/, '').gsub(/\W+/, '_')
    name = basename + extname
    ::Kernel.srand
    ::File.join ::Dir.tmpdir, "unix_utils-#{::Kernel.rand(1e11)}-#{name}"
  end

  def self.spawn(*argv) # :nodoc:
    argv = argv.dup
    options = argv.last.is_a?(::Hash) ? argv.pop : {}
    
    if options[:chdir]
      old_pwd = ::Dir.pwd
      ::Dir.chdir options[:chdir]
    end
    
    whole_stdout = nil
    whole_stderr = nil

    ::Open3.popen3(*argv) do |stdin, stdout, stderr|
      # deal with STDIN
      if options[:read_from]
        ::File.open(options[:read_from], 'r') do |in_f|
          while chunk = in_f.read(4_194_304)
            stdin.write chunk
          end
        end
      end
      stdin.close

      # deal with STDOUT
      if options[:write_to]
        ::File.open(options[:write_to], 'wb') do |out_f|
          while chunk = stdout.read(4_194_304)
            out_f.write chunk
          end
        end
        whole_stdout = "Redirected to #{options[:write_to]}"
      else
        whole_stdout = stdout.read
      end
      
      # deal with STDERR
      whole_stderr = stderr.read
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
