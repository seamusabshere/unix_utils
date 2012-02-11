# encoding: UTF-8
require 'helper'

describe UnixUtils do
  describe :curl do
    it "downloads to a temp file" do
      out_path = UnixUtils.curl('http://brighterplanet.com')
      File.read(out_path).must_match %r{sustain}i
      rm_rf out_path
    end
  end
  
  describe :sha265 do
    it "checksums a file" do
      in_path = ready_made(:zip)
      UnixUtils.sha256(in_path).must_equal ZIP_SHA256
    end
  end
  
  describe :du do
    it "calculates the size of a directory" do
      in_path = to_be_processed(:dir)
      UnixUtils.du(in_path).must_equal DIR_SIZE
    end
  end

  [ :unzip, :untar ].each do |method_id|
    describe method_id do
      it "outputs a DIRECTORY located in the tmp directory" do
        in_path = ready_made(method_id)
        out_dir = UnixUtils.send method_id, in_path
        File.directory?(out_dir).must_equal true
        Dir.entries(out_dir).must_equal ARCHIVE_ENTRIES
        File.dirname(out_dir).start_with?(Dir.tmpdir).must_equal true
        rm_rf out_dir
      end
      it "accepts unsemantic filenames" do
        in_path = anonymous_ready_made(method_id)
        out_dir = UnixUtils.send method_id, in_path
        File.directory?(out_dir).must_equal true
        Dir.entries(out_dir).must_equal ARCHIVE_ENTRIES
        File.dirname(out_dir).start_with?(Dir.tmpdir).must_equal true
        rm_rf out_dir
      end
    end
  end
  
  [ :bunzip2, :gunzip ].each do |method_id|
    describe method_id do
      it "outputs a FILE located in the tmp directory" do
        in_path = ready_made(method_id)
        out_path = UnixUtils.send method_id, in_path
        File.file?(out_path).must_equal true
        `file #{out_path}`.chomp.must_match %r{text}
        File.dirname(out_path).start_with?(Dir.tmpdir).must_equal true
        rm_rf out_path
      end
      it "accepts unsemantic filenames" do
        in_path = anonymous_ready_made(method_id)
        out_path = UnixUtils.send method_id, in_path
        File.file?(out_path).must_equal true
        `file #{out_path}`.chomp.must_match %r{text}
        File.dirname(out_path).start_with?(Dir.tmpdir).must_equal true
        rm_rf out_path
      end
    end
  end

  [ :unzip, :untar, :bunzip2, :gunzip ].each do |method_id|
    describe method_id do
      it "does not touch the input" do
        in_path = ready_made(method_id)
        mtime = File.mtime in_path
        checksum = UnixUtils.sha256 in_path
        out_dir = UnixUtils.send method_id, in_path
        rm_rf out_dir
        File.mtime(in_path).must_equal mtime
        UnixUtils.sha256(in_path).must_equal checksum
      end
    end
  end

  [ :bzip2, :gzip, :zip, :tar ].each do |method_id|
    describe method_id do
      it "stores a #{TestHelper.what_do_i_hold(method_id)} to a FILE in the tmp directory" do
        in_path = to_be_processed(method_id)
        out_path = UnixUtils.send method_id, in_path
        File.file?(out_path).must_equal true
        `file #{out_path}`.chomp.must_match %r{\b#{method_id.downcase}\b}
        File.dirname(out_path).start_with?(Dir.tmpdir).must_equal true
        rm_rf out_path
      end
      
      it "does not touch the input" do
        in_path = to_be_processed(method_id)
        mtime = File.mtime in_path
        case TestHelper.what_do_i_hold(method_id)
        when :file
          checksum = UnixUtils.sha256 in_path
        when :directory
          size = UnixUtils.du in_path
        end
        out_dir = UnixUtils.send method_id, in_path
        rm_rf out_dir
        File.mtime(in_path).must_equal mtime
        case TestHelper.what_do_i_hold(method_id)
        when :file
          checksum = UnixUtils.sha256 in_path
          UnixUtils.sha256(in_path).must_equal checksum
        when :directory
          UnixUtils.du(in_path).must_equal size
        end
      end
    end
  end
  
  # it 'unix2dos in place' do
  # 
  # end
  # 
  # it 'wc -l' do
  # 
  # end
  # 
  # it 'sed (really gsed)' do
  # 
  # end

  # it 'does stuff in place' do
  #   Utils.in_place t.local_file.path, 'tail', '-n', "+#{t.properties.skip + 1}"
  #
  #   def crop_rows!
  #     Utils.in_place t.local_file.path, 'tail', '-n', "+#{t.properties.crop.first}"
  #     Utils.in_place t.local_file.path, 'head', '-n', (t.properties.crop.last - t.properties.crop.first + 1).to_s
  #   end
  #
  #   def cut_columns!
  #     Utils.in_place t.local_file.path, 'cut', '-c', t.properties.cut.to_s
  # end

  # it 'head' do
  # 
  # end
  # 
  # it 'iconv' do
  # 
  # end
  # 
  # it 'cut' do
  # 
  # end
end
