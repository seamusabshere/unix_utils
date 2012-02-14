# encoding: UTF-8
require 'helper'

describe UnixUtils do
  before do
    @old_pwd = Dir.pwd
    Dir.chdir File.expand_path('../target', __FILE__)
  end
  
  after do
    Dir.chdir @old_pwd
  end
  
  describe :curl do
    it "downloads to a temp file" do
      outfile = UnixUtils.curl('http://brighterplanet.com')
      File.read(outfile).must_match %r{sustain}i
      rm_rf outfile
    end
  end
  
  describe :sha265 do
    it "checksums a file" do
      UnixUtils.sha256('directory.zip').must_equal '661af2b7b0993088263228b071b649a88d82a6a655562162c32307d1e127f27a'
    end
  end
  
  describe :du do
    it "calculates the size of a directory in bytes" do
      UnixUtils.du('directory').must_equal 16
    end
  end
  
  describe :unzip do
    before do
      @infile = 'directory.zip'
      @anonymous_infile = 'directory-really-a-z_i_p-shh'
    end
    it "unpacks a DIRECTORY located in the tmp directory" do
      assert_unpack_dir :unzip, @infile
    end
    it "accepts unsemantic filenames" do
      assert_unpack_dir :unzip, @anonymous_infile
    end
    it "does not touch the infile" do
      assert_does_not_touch :unzip, @infile
    end
  end
  
  describe :untar do
    before do
      @infile = 'directory.tar'
      @anonymous_infile = 'directory-really-a-t_a_r-shh'
    end
    it "unpacks a DIRECTORY located in the tmp directory" do
      assert_unpack_dir :untar, @infile
    end
    it "accepts unsemantic filenames" do
      assert_unpack_dir :untar, @anonymous_infile
    end
    it "does not touch the infile" do
      assert_does_not_touch :untar, @infile
    end
  end
  
  describe :bunzip2 do
    before do
      @infile = 'file.bz2'
      @anonymous_infile = 'file-really-a-b_z_2-shh'
    end
    it "unpacks a FILE located in the tmp directory" do
      assert_unpack_file :bunzip2, @infile
    end
    it "accepts unsemantic filenames" do
      assert_unpack_file :bunzip2, @anonymous_infile
    end
    it "does not touch the infile" do
      assert_does_not_touch :bunzip2, @infile
    end
  end
  
  describe :gunzip do
    before do
      @infile = 'file.gz'
      @anonymous_infile = 'file-really-a-g_z-shh'
    end
    it "unpacks a FILE located in the tmp directory" do
      assert_unpack_file :gunzip, @infile
    end
    it "accepts unsemantic filenames" do
      assert_unpack_file :gunzip, @anonymous_infile
    end
    it "does not touch the infile" do
      assert_does_not_touch :gunzip, @infile
    end
  end
  
  describe :bzip2 do
    before do
      @infile = 'directory.tar'
    end
    it "packs a FILE to a FILE in the tmp directory" do
      assert_pack :bzip2, @infile
    end
    it "does not touch the infile" do
      assert_does_not_touch :bzip2, @infile
    end
  end
  
  describe :gzip do
    before do
      @infile = 'directory.tar'
    end
    it "packs a FILE to a FILE in the tmp directory" do
      assert_pack :gzip, @infile
    end
    it "does not touch the infile" do
      assert_does_not_touch :gzip, @infile
    end
  end
  
  describe :zip do
    before do
      @srcdir = 'directory'
    end
    it "packs a DIRECTORY to a FILE in the tmp directory" do
      assert_pack :zip, @srcdir
    end
    it "does not touch the infile" do
      assert_does_not_touch :zip, @srcdir
    end
  end
  
  describe :tar do
    before do
      @srcdir = 'directory'
    end
    it "packs a DIRECTORY to a FILE in the tmp directory" do
      assert_pack :tar, @srcdir
    end
    it "does not touch the infile" do
      assert_does_not_touch :tar, @srcdir
    end
  end
  
  # describe :unix2dos do
  #   it 'converts newlines' do
  #   end
  # end
  # 
  # describe :dos2unix do
  #   it 'converts newlines' do
  #   end
  # end
  # 
  # describe :wc do
  #   it 'counts words' do
  #   end
  # end
  # 
  # # replace in-place
  # describe :sed do
  #   
  # end
  # 
  # # 'tail', '-n', "+#{t.properties.skip + 1}"
  # # 'tail', '-n', "+#{t.properties.crop.first}"
  # describe :tail do
  #   it 'tails a file' do
  #     
  #   end
  # end
  # 
  # # 'head', '-n', (t.properties.crop.last - t.properties.crop.first + 1).to_s
  # describe :head do
  #   it 'looks at the head of a file' do
  #   end
  # end
  # 
  # # 'cut', '-c', t.properties.cut.to_s
  # describe :cut do
  #   it 'deals with columns in a file' do
  #   end
  # end
  # 
  # describe :iconv do
  #   it 'converts files from one encoding to another' do
  #   end
  # end
end
