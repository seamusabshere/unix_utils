require 'bundler/setup'

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'unix_utils'

require 'fileutils'
require 'tmpdir'

module TestHelper
  def assert_does_not_touch(method_id, infile_or_srcdir)
    mtime = File.mtime infile_or_srcdir
    kind = File.file?(infile_or_srcdir) ? :file : :directory
    case kind
    when :file
      checksum = UnixUtils.sha256 infile_or_srcdir
    when :directory
      size = UnixUtils.du infile_or_srcdir
    end
    destdir = UnixUtils.send method_id, infile_or_srcdir
    rm_rf destdir
    File.mtime(infile_or_srcdir).must_equal mtime
    case kind
    when :file
      UnixUtils.sha256(infile_or_srcdir).must_equal checksum
    when :directory
      UnixUtils.du(infile_or_srcdir).must_equal size
    end
  end
  
  def assert_unpack_dir(method_id, infile)
    destdir = UnixUtils.send method_id, infile
    File.directory?(destdir).must_equal true
    Dir.entries(destdir).must_equal %w{ . .. hello_world.txt hello_world.xml }
    File.dirname(destdir).start_with?(Dir.tmpdir).must_equal true
    rm_rf destdir
  end
  
  def assert_unpack_file(method_id, infile)
    outfile = UnixUtils.send method_id, infile
    File.file?(outfile).must_equal true
    `file #{outfile}`.chomp.must_match %r{text}
    File.dirname(outfile).start_with?(Dir.tmpdir).must_equal true
    rm_rf outfile
  end
    
  def assert_pack(method_id, infile)
    outfile = UnixUtils.send method_id, infile
    File.file?(outfile).must_equal true
    `file #{outfile}`.chomp.must_match %r{\b#{method_id.to_s.downcase}\b}
    File.dirname(outfile).start_with?(Dir.tmpdir).must_equal true
    rm_rf outfile
  end
  
  def rm_rf(path)
    path = File.expand_path path
    raise "Refusing to rm_rf #{path} because it's not in #{Dir.tmpdir}" unless File.dirname(path).start_with?(Dir.tmpdir)
    FileUtils.rm_rf path
  end
end

class MiniTest::Spec
  include TestHelper
end
