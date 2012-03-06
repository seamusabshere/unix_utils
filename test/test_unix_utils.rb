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
      safe_delete outfile
    end
  end

  describe :shasum do
    it "checksums a file with SHA-1" do
      UnixUtils.shasum('directory.zip', 1).must_equal 'c0abb36c923ed7bf87ebb8d7097cb8e264e528d2'
    end
    it "checksums a file with SHA-256" do
      UnixUtils.shasum('directory.zip', 256).must_equal '661af2b7b0993088263228b071b649a88d82a6a655562162c32307d1e127f27a'
    end
    it "works just as well with absolute paths" do
      target_path = File.join(Dir.pwd, 'directory.zip')
      Dir.chdir('/') do
        UnixUtils.shasum(target_path, 256).must_equal '661af2b7b0993088263228b071b649a88d82a6a655562162c32307d1e127f27a'
      end
    end
  end

  describe :md5sum do
    it "checksums a file" do
      UnixUtils.md5sum('directory.zip').must_equal 'd6e15da798ae19551da6c49ec09afaef'
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
    it "sticks on a useful extension" do
      outfile = UnixUtils.bzip2 @infile
      File.extname(outfile).must_equal '.bz2'
      safe_delete outfile
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
    it "sticks on a useful extension" do
      outfile = UnixUtils.gzip @infile
      File.extname(outfile).must_equal '.gz'
      safe_delete outfile
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
    it "sticks on a useful extension" do
      outfile = UnixUtils.zip @srcdir
      File.extname(outfile).must_equal '.zip'
      safe_delete outfile
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
    it "sticks on a useful extension" do
      outfile = UnixUtils.tar @srcdir
      File.extname(outfile).must_equal '.tar'
      safe_delete outfile
    end
  end

  describe :perl do
    before do
      @f = Tempfile.new('perl.txt')
      @f.write "bad\n"*10
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it "processes a file" do
      outfile = UnixUtils.perl(@infile, 's/bad/good/g')
      File.read(outfile).must_equal "good\n"*10
      safe_delete outfile
    end
    it "does not touch the infile" do
      assert_does_not_touch :perl, @infile, 's/bad/good/g'
    end
    it "keeps the original extname" do
      outfile = UnixUtils.perl(@infile, 's/bad/good/g')
      File.extname(outfile).must_equal File.extname(@infile)
      safe_delete outfile
    end
  end

  describe :awk do
    before do
      @f = Tempfile.new('awk.txt')
      @f.write "bad\n"*10
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it "processes a file" do
      outfile = UnixUtils.awk(@infile, '{gsub(/bad/, "good"); print}')
      File.read(outfile).must_equal "good\n"*10
      safe_delete outfile
    end
    it "does not touch the infile" do
      assert_does_not_touch :awk, @infile, '{gsub(/bad/, "good"); print}'
    end
    it "keeps the original extname" do
      outfile = UnixUtils.awk(@infile, '{gsub(/bad/, "good"); print}')
      File.extname(outfile).must_equal File.extname(@infile)
      safe_delete outfile
    end
  end

  describe :unix2dos do
    before do
      @f = Tempfile.new('unix2dos.txt')
      @f.write "unix\n"*5
      @f.write "dos\r\n"*5
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it 'converts newlines' do
      outfile = UnixUtils.unix2dos @infile
      File.read(outfile).must_equal("unix\r\n"*5 + "dos\r\n"*5)
      safe_delete outfile
    end
  end

  describe :dos2unix do
    before do
      @f = Tempfile.new('dos2unix.txt')
      @f.write "dos\r\n"*5
      @f.write "unix\n"*5
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it 'converts newlines' do
      outfile = UnixUtils.dos2unix @infile
      File.read(outfile).must_equal("dos\n"*5 + "unix\n"*5)
      safe_delete outfile
    end
  end

  describe :wc do
    before do
      @f = Tempfile.new('wc.txt')
      @f.write "dos line\r\n"*5
      @f.write "unix line\n"*5
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it 'counts lines, words, and bytes' do
      UnixUtils.wc(@infile).must_equal [5+5, 10+10, 50+50]
    end
  end

  describe :sed do
    before do
      @f = Tempfile.new('sed.txt')
      @f.write "bad\n"*10
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it "processes a file" do
      outfile = UnixUtils.sed(@infile, 's/bad/good/g')
      File.read(outfile).must_equal "good\n"*10
      safe_delete outfile
    end
    it "does not touch the infile" do
      assert_does_not_touch :sed, @infile, 's/bad/good/g'
    end
    it "keeps the original extname" do
      outfile = UnixUtils.sed(@infile, 's/bad/good/g')
      File.extname(outfile).must_equal File.extname(@infile)
      safe_delete outfile
    end

  end

  describe :tail do
    before do
      @a2z = ('a'..'z').to_a
      @f = Tempfile.new('tail.txt')
      @f.write @a2z.join("\n")
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it 'gets last three lines' do
      outfile = UnixUtils.tail(@infile, 3)
      File.read(outfile).must_equal @a2z.last(3).join("\n")
      safe_delete outfile
    end
    it 'gets trailing lines starting with the third line (inclusive)' do
      outfile = UnixUtils.tail(@infile, '+3')
      File.read(outfile).must_equal @a2z[2..-1].join("\n")
      safe_delete outfile
    end
  end

  describe :head do
    before do
      @a2z = ('a'..'z').to_a
      @f = Tempfile.new('head.txt')
      @f.write @a2z.join("\n")
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it 'gets first three lines' do
      outfile = UnixUtils.head(@infile, 3)
      File.read(outfile).must_equal(@a2z.first(3).join("\n") + "\n")
      safe_delete outfile
    end
  end

  describe :cut do
    before do
      @a2z = ('a'..'z').to_a
      @f = Tempfile.new('cut.txt')
      10.times do
        @f.write(@a2z.join + "\n")
      end
      @f.flush
      @infile = @f.path
    end
    after do
      @f.close
    end
    it 'cuts out character positions' do
      outfile = UnixUtils.cut(@infile, '1,12,13,15,19,20')
      almosts = (0..9).map { |i| 'almost' }.join("\n") + "\n"
      File.read(outfile).must_equal almosts
      safe_delete outfile
    end
    it 'cuts out character ranges (inclusive)' do
      outfile = UnixUtils.cut(@infile, '3-6')
      cdefs = (0..9).map { |i| 'cdef' }.join("\n") + "\n"
      File.read(outfile).must_equal cdefs
      safe_delete outfile
    end
  end

  describe :iconv do
    it 'converts files from utf-8 to latin1' do
      outfile = UnixUtils.iconv('utf8.txt', 'ISO-8859-1', 'UTF-8')
      UnixUtils.md5sum(outfile).must_equal UnixUtils.md5sum('iso-8859-1.txt')
      safe_delete outfile
    end
    it 'converts files from latin1 to utf-8' do
      outfile = UnixUtils.iconv('iso-8859-1.txt', 'UTF-8', 'ISO-8859-1')
      UnixUtils.md5sum(outfile).must_equal UnixUtils.md5sum('utf8.txt')
      safe_delete outfile
    end
  end
end
