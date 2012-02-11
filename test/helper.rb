require 'bundler/setup'

require 'minitest/spec'
require 'minitest/autorun'
require 'minitest/reporters'
MiniTest::Unit.runner = MiniTest::SuiteRunner.new
MiniTest::Unit.runner.reporters << MiniTest::Reporters::SpecReporter.new

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'unix_utils'

READY_MADE_DIR = ::File.expand_path('../ready_made', __FILE__)
TO_BE_PROCESSED_DIR = ::File.expand_path('../to_be_processed', __FILE__)
ZIP_SHA256 = '661af2b7b0993088263228b071b649a88d82a6a655562162c32307d1e127f27a'
DIR_SIZE = 16
ARCHIVE_ENTRIES = %w{ . .. hello_world.txt hello_world.xml }

require 'fileutils'
require 'tmpdir'

module TestHelper
  extend self
  
  def ready_made(method_id_or_extname)
    ::File.join READY_MADE_DIR, "#{what_do_i_hold(method_id_or_extname)}.#{extname(method_id_or_extname)}"
  end

  def anonymous_ready_made(method_id_or_extname)
    ::File.join READY_MADE_DIR, "#{what_do_i_hold(method_id_or_extname)}-really-a-#{extname(method_id_or_extname).to_s.chars.to_a.join('_')}-shh"
  end
  
  def to_be_processed(method_id_or_extname)
    return TO_BE_PROCESSED_DIR if method_id_or_extname == :dir
    
    case what_do_i_hold(method_id_or_extname)
    when :file
      ::File.join TO_BE_PROCESSED_DIR, 'hello_world.txt'
    when :directory
      TO_BE_PROCESSED_DIR
    end
  end
  
  def extname(method_id_or_extname)
    case method_id_or_extname.to_s.downcase
    when /b.*z/
      :bz2
    when /g.*z/
      :gz
    when /tar/
      :tar
    when /zip/
      :zip
    end
  end

  def what_do_i_hold(method_id_or_extname)
    case method_id_or_extname.to_s.downcase
    when /b.*z/, /g.*z/
      :file
    when /zip/, /tar/
      :directory
    end
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
