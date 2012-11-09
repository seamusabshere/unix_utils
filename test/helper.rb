require 'rubygems'
require 'bundler/setup'
require 'pry'

require 'minitest/spec'
require 'minitest/autorun'
if RUBY_VERSION >= '1.9'
  require 'minitest/reporters'
  MiniTest::Reporters.use! MiniTest::Reporters::SpecReporter.new
end

require 'unix_utils'

require 'stringio'
require 'fileutils'
require 'tmpdir'
require 'tempfile'

module TestHelper
  def assert_does_not_touch(method_id, *args)
    infile_or_srcdir = args.first
    mtime = File.mtime infile_or_srcdir
    kind = File.file?(infile_or_srcdir) ? :file : :directory
    case kind
    when :file
      checksum = UnixUtils.shasum infile_or_srcdir, 256
    when :directory
      size = UnixUtils.du infile_or_srcdir
    end
    destdir = UnixUtils.send(*([method_id] + args))
    safe_delete destdir
    File.mtime(infile_or_srcdir).must_equal mtime
    case kind
    when :file
      UnixUtils.shasum(infile_or_srcdir, 256).must_equal checksum
    when :directory
      UnixUtils.du(infile_or_srcdir).must_equal size
    end
  end

  def assert_unpack_dir(method_id, infile)
    destdir = UnixUtils.send method_id, infile
    File.directory?(destdir).must_equal true
    Dir.entries(destdir).must_equal %w{ . .. hello_world.txt hello_world.xml }
    File.dirname(destdir).start_with?(Dir.tmpdir).must_equal true
    safe_delete destdir
  end

  def assert_unpack_file(method_id, infile)
    outfile = UnixUtils.send method_id, infile
    File.file?(outfile).must_equal true
    `file #{outfile}`.chomp.must_match %r{text}
    File.dirname(outfile).start_with?(Dir.tmpdir).must_equal true
    safe_delete outfile
  end

  def assert_pack(method_id, infile)
    outfile = UnixUtils.send method_id, infile
    File.file?(outfile).must_equal true
    `file #{outfile}`.chomp.must_match %r{\b#{method_id.to_s.downcase}\b}
    File.dirname(outfile).start_with?(Dir.tmpdir).must_equal true
    safe_delete outfile
  end

  def safe_delete(path)
    path = File.expand_path path
    raise "Refusing to rm -rf #{path} because it's not in #{Dir.tmpdir}" unless File.dirname(path).start_with?(Dir.tmpdir)
    FileUtils.rm_rf path
  end
end

class MiniTest::Spec
  include TestHelper
end
