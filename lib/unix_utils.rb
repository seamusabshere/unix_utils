require 'fileutils'
require 'tmpdir'
require 'uri'
require 'stringio'
require 'open3'
require 'securerandom'
require "unix_utils/version"

module UnixUtils

  BUFSIZE = 2**16

  def self.curl(url, form_data = nil)
    outfile = tmp_path url
    if url.start_with?('file://') or not url.include?('://')
      # deal with local files
      infile = File.expand_path url.sub('file://', '')
      unless File.readable?(infile)
        raise "[unix_utils] #{url.inspect} does not exist or is not readable on the local filesystem."
      end
      FileUtils.cp infile, outfile
      return outfile
    end
    uri = URI.parse url
    argv = [ 'curl', '--location', '--show-error', '--silent', '--compressed', '--header', 'Expect: ' ]
    if form_data
      argv += [ '--data', form_data ]
    end
    argv += [ uri.to_s, '--output', outfile ]
    spawn argv
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
    infile = File.expand_path infile
    if available?('shasum')
      argv = ['shasum', '--binary', '-a', algorithm.to_s, infile]
      stdout = spawn argv
      stdout.strip.split(' ').first
    else
      argv = ['openssl', 'dgst', "-sha#{algorithm}", infile]
      stdout = spawn argv
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
    infile = File.expand_path infile
    if available?('md5sum')
      argv = ['md5sum', '--binary', infile]
      stdout = spawn argv
      stdout.strip.split(' ').first
    else
      argv = ['openssl', 'dgst', '-md5', infile]
      stdout = spawn argv
      stdout.strip.split(' ').last
    end
  end

  def self.du(srcdir)
    srcdir = File.expand_path srcdir
    argv = ['du', '-sk', srcdir]
    stdout = spawn argv
    stdout.strip.split(/\s+/).first.to_i
  end

  def self.wc(infile)
    infile = File.expand_path infile
    argv = ['wc', infile]
    stdout = spawn argv
    stdout.strip.split(/\s+/)[0..2].map { |s| s.to_i }
  end

  # --

  def self.unzip(infile)
    infile = File.expand_path infile
    destdir = tmp_path infile
    FileUtils.mkdir destdir
    argv = ['unzip', '-qq', '-n', infile, '-d', destdir]
    spawn argv
    destdir
  end

  def self.untar(infile)
    infile = File.expand_path infile
    destdir = tmp_path infile
    FileUtils.mkdir destdir
    argv = ['tar', '-xf', infile, '-C', destdir]
    spawn argv
    destdir
  end

  def self.gunzip(infile)
    infile = File.expand_path infile
    outfile = tmp_path infile
    argv = ['gunzip', '--stdout', infile]
    spawn argv, :write_to => outfile
    outfile
  end

  def self.bunzip2(infile)
    infile = File.expand_path infile
    outfile = tmp_path infile
    argv = ['bunzip2', '--stdout', infile]
    spawn argv, :write_to => outfile
    outfile
  end

  # --

  def self.bzip2(infile)
    infile = File.expand_path infile
    outfile = tmp_path infile, '.bz2'
    argv = ['bzip2', '--keep', '--stdout', infile]
    spawn argv, :write_to => outfile
    outfile
  end

  def self.tar(srcdir)
    srcdir = File.expand_path srcdir
    outfile = tmp_path srcdir, '.tar'
    argv = ['tar', '-cf', outfile, '-C', srcdir, '.']
    spawn argv
    outfile
  end

  def self.zip(srcdir)
    srcdir = File.expand_path srcdir
    outfile = tmp_path srcdir, '.zip'
    argv = ['zip', '-rq', outfile, '.']
    spawn argv, :chdir => srcdir
    outfile
  end

  def self.gzip(infile)
    infile = File.expand_path infile
    outfile = tmp_path infile, '.gz'
    argv = ['gzip', '--stdout', infile]
    spawn argv, :write_to => outfile
    outfile
  end

  # --

  def self.awk(infile, *expr)
    infile = File.expand_path infile
    outfile = tmp_path infile
    bin = available?('gawk') ? 'gawk' : 'awk'
    argv = [bin, expr, infile].flatten
    spawn argv, :write_to => outfile
    outfile
  end

  # Yes, this is a very limited use of perl.
  def self.perl(infile, *expr)
    infile = File.expand_path infile
    outfile = tmp_path infile
    argv = [ 'perl', expr.map { |e| ['-pe', e] }, infile ].flatten
    spawn argv, :write_to => outfile
    outfile
  end

  def self.unix2dos(infile)
    infile = File.expand_path infile
    if available?('gawk') or available?('awk')
      awk infile, '{ sub(/\r/, ""); printf("%s\r\n", $0) }'
    else
      perl infile, 's/\r\n|\n|\r/\r\n/g'
    end
  end

  def self.dos2unix(infile)
    infile = File.expand_path infile
    if available?('gawk') or available?('awk')
      awk infile, '{ sub(/\r/, ""); printf("%s\n", $0) }'
    else
      perl infile, 's/\r\n|\n|\r/\n/g'
    end
  end

  # POSIX sed, whether it's provided by sed or gsed
  def self.sed(infile, *expr)
    infile = File.expand_path infile
    outfile = tmp_path infile
    bin = available?('sed') ? 'sed' : ['gsed', '--posix']
    argv = [ bin, expr.map { |e| ['-e', e] }, infile ].flatten
    spawn argv, :write_to => outfile
    outfile
  end

  def self.tail(infile, lines)
    infile = File.expand_path infile
    outfile = tmp_path infile
    argv = ['tail', '-n', lines.to_s, infile]
    spawn argv, :write_to => outfile
    outfile
  end

  def self.head(infile, lines)
    infile = File.expand_path infile
    outfile = tmp_path infile
    argv = ['head', '-n', lines.to_s, infile]
    spawn argv, :write_to => outfile
    outfile
  end

  # specify character_positions as a string like "3-5" or "3,9-10"
  def self.cut(infile, character_positions)
    infile = File.expand_path infile
    outfile = tmp_path infile
    argv = ['cut', '-c', character_positions, infile]
    spawn argv, :write_to => outfile
    outfile
  end

  def self.iconv(infile, to, from)
    infile = File.expand_path infile
    outfile = tmp_path infile
    argv = ['iconv', '-c', '-t', to, '-f', from, infile]
    spawn argv, :write_to => outfile
    outfile
  end

  def self.available?(bin) # :nodoc:
    bin = bin.to_s
    return @@available_query[bin] if defined?(@@available_query) and @@available_query.is_a?(Hash) and @@available_query.has_key?(bin)
    @@available_query ||= {}
    `which #{bin}`
    @@available_query[bin] = $?.success?
  end

  def self.tmp_path(ancestor, extname = nil) # :nodoc:
    ancestor = ancestor.to_s
    extname ||= File.extname ancestor
    basename = File.basename ancestor.gsub(/unix_utils_[a-f0-9]{8,}_/, '')
    basename.gsub! /\W+/, '_'
    File.join Dir.tmpdir, "unix_utils_#{SecureRandom.hex(4)}_#{basename[0..(234-extname.length)]}#{extname}"
  end

  def self.spawn(argv, options = {}) # :nodoc:
    input = if (read_from = options[:read_from])
      if RUBY_DESCRIPTION =~ /jruby 1.7.0/
        raise "[unix_utils] Can't use `#{argv.first}` since JRuby 1.7.0 has a broken IO implementation!"
      end
      File.open(read_from, 'r')
    end
    output = if (write_to = options[:write_to])
      output_redirected = true
      File.open(write_to, 'wb')
    else
      output_redirected = false
      StringIO.new
    end
    error = StringIO.new
    if (chdir = options[:chdir])
      Dir.chdir(chdir) do
        _spawn argv, input, output, error
      end
    else
      _spawn argv, input, output, error
    end
    error.rewind
    unless (whole_error = error.read).empty?
      $stderr.puts "[unix_utils] `#{argv.join(' ')}` STDERR:"
      $stderr.puts whole_error
    end
    unless output_redirected
      output.rewind
      output.read
    end
  ensure
    [input, output, error].each { |io| io.close if io and not io.closed? }
  end

  def self._spawn(argv, input, output, error)
    # lifted from posix-spawn
    # https://github.com/rtomayko/posix-spawn/blob/master/lib/posix/spawn/child.rb
    Open3.popen3(*argv) do |stdin, stdout, stderr|
      readers = [stdout, stderr]
      if RUBY_DESCRIPTION =~ /jruby 1.7.0/
        readers.delete stderr
      end
      writers = if input
        [stdin]
      else
        stdin.close
        []
      end
      while readers.any? or writers.any?
        ready = IO.select(readers, writers, readers + writers)
        # write to stdin stream
        ready[1].each do |fd|
          begin
            boom = nil
            size = fd.write input.read(BUFSIZE)
          rescue Errno::EPIPE => boom
          rescue Errno::EAGAIN, Errno::EINTR
          end
          if boom || size < BUFSIZE
            stdin.close
            input.close
            writers.delete stdin
          end
        end
        # read from stdout and stderr streams
        ready[0].each do |fd|
          buf = (fd == stdout) ? output : error
          if fd.eof?
            readers.delete fd
            fd.close
          else
            begin
              buf << fd.readpartial(BUFSIZE)
            rescue Errno::EAGAIN, Errno::EINTR
            end
          end
        end
      end
      # thanks @tmm1 and @rtomayko for showing how it's done!
    end
  end

  def self.method_missing(method_id, *args)
    base_method_id = method_id.to_s.chomp('_s')
    if respond_to?(base_method_id)
      begin
        outfile = send(*([base_method_id]+args))
        File.read outfile
      ensure
        FileUtils.rm_f outfile
      end
    else
      super
    end
  end
end
