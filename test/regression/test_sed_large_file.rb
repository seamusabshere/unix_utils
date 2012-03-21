# encoding: UTF-8
require 'helper'
require 'tempfile'

describe "handle large file with sed" do
  let(:normal_line_no)  { 124000 }
  let(:invalid_line_no) { 10 }
  let(:input_file)      { Tempfile.open('test', '/tmp') }

  before do
    begin
      (1..normal_line_no).each do |i|
        input_file.puts "\"psmith01\",\"CLASS2B\",\"Peter Smith 1\",\"YEAR2\",\"1\",\"N\",\"ADVANCED\",\"STAFF\",\"1\",\"Y\",\"Y\",\"psmith01\",\"CLASS2B\",\"Peter Smith 1\",\"YEAR2\",\"1\",\"N\",\"ADVANCED\",\"STAFF\",\"1\",\"Y\",\"Y\",\"psmith01\",\"CLASS2B\",\"Peter Smith 1\",\"YEAR2\",\"1\",\"N\",\"ADVANCED\",\"STAFF\",\"1\",\"Y\",\"Y\",\"psmith01\",\"CLASS2B\",\"Peter Smith 1\",\"YEAR2\",\"1\",\"N\",\"ADVANCED\",\"STAFF\",\"1\",\"Y\",\"Y\""
      end
      (1..invalid_line_no).each do |i|
        input_file.puts "@!!@"
      end
      input_file.flush
    ensure
      input_file.close
    end
  end

  it "should have 124000 lines in output file" do
    output_path = UnixUtils.sed(input_file.path, ':a', "1,#{invalid_line_no}!{P;N;D;};N;ba")
    UnixUtils.wc(output_path).first.must_equal normal_line_no
  end

  after do
    input_file.unlink
  end
end
