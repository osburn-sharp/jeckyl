require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'jeckyl/errors'
require 'jeckyl'
require File.expand_path(File.dirname(__FILE__) + '/../test/test_configurator')

conf_path = File.expand_path(File.dirname(__FILE__) + '/../test/conf.d')

report_path = File.expand_path(File.dirname(__FILE__) + '/../test/reports')

describe "Jeckyl Config Checker" do

  # general tests

  it "should checkout a simple config" do
    conf_file = conf_path + '/jeckyl'
    rep_file = report_path + '/ok.txt'
    conf_ok = TestJeckyl.check_config(conf_file, rep_file)
    conf_ok.should be_true
    message = File.read(rep_file).chomp
    message.should == "No errors found in: #{conf_file}"
  end


  it "should complain if the config file does not exist" do
    conf_file = conf_path + "/never/likely/to/be/there"
    rep_file = report_path + '/not_ok.txt'
    conf_ok = TestJeckyl.check_config(conf_file, rep_file)
    conf_ok.should be_false
    message = File.read(rep_file).chomp
    message.should == "No such config file: #{conf_file}"
  end

  it "should return false if the config file has a syntax error" do
    conf_file = conf_path + "/syntax_error"
    rep_file = report_path + '/not_ok.txt'
    conf_ok = TestJeckyl.check_config(conf_file, rep_file)
    conf_ok.should be_false
    message = File.read(rep_file).chomp
    message.should match(/^compile error/)
  end

  it "should return false if the config file has an error" do
    conf_file = conf_path + "/not_a_bool"
    rep_file = report_path + '/not_ok.txt'
    conf_ok = TestJeckyl.check_config(conf_file, rep_file)
    conf_ok.should be_false
    message = File.read(rep_file).chomp
    message.should match(/^\[debug\]:/)
  end

  it "should fail if it cannot write to the report file" do
    conf_file = conf_path + "/jeckyl"
    rep_file = report_path + '/no_such_directory/ok.txt'
    lambda{conf_ok = TestJeckyl.check_config(conf_file, rep_file)}.should raise_error(Jeckyl::ReportFileError)
  end

end
