require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'jeckyl/errors'
require File.expand_path(File.dirname(__FILE__) + '/../test/test_configurator')

conf_path = File.expand_path(File.dirname(__FILE__) + '/../conf.d')

describe "Jeckyl" do
  it "should create a simple config" do
    conf_file = conf_path + '/jeckyl'
    conf = TestJeckyl.new(conf_file)
    conf[:log_dir].should match(/jelly\/log$/)
    conf[:log_level].should == :verbose
    conf[:log_rotation].should == 5
  end

  it "should fail if the config file does not exist" do
    conf_file = conf_path + "/never/likely/to/be/there"
    lambda{conf = TestJeckyl.new(conf_file)}.should raise_error(Jeckyl::ConfigFileMissing, conf_file)
  end

  it "should be easy to set simple defaults" do
    conf_file = conf_path + '/jeckyl'
    defaults = {:master_key => 'ABCDEF'}
    conf = TestJeckyl.new(conf_file, defaults)
    conf[:master_key].should == 'ABCDEF'
  end

  it "should raise an exception if a file parameter does not exist" do
    conf_file = conf_path + '/bad_filename'
    lambda{conf = TestJeckyl.new(conf_file)}.should raise_error(Jeckyl::ConfigError, /^\[log_dir\]:/)
  end

  it "should raise an exception if a dir is not writable" do
    conf_file = conf_path + '/unwritable_dir'
    lambda{conf = TestJeckyl.new(conf_file)}.should raise_error(Jeckyl::ConfigError, /^\[log_dir\]:/)
  end

  it "should raise an exception if there is a syntax error" do
    conf_file = conf_path + '/syntax_error'
    lambda{conf = TestJeckyl.new(conf_file)}.should raise_error(Jeckyl::ConfigSyntaxError)
  end

  it "should raise an exception if there is an unknown parameter used" do
    conf_file = conf_path + '/unknown_param'
    lambda{conf = TestJeckyl.new(conf_file)}.should raise_error(Jeckyl::UnknownParameter)
  end

  it "should raise an exception if there is an invalid integer" do
    conf_file = conf_path + '/wrong_integer'
    lambda{conf = TestJeckyl.new(conf_file)}.should raise_error(Jeckyl::ConfigError, /^\[log_rotation\]:.*value is not an within required range: 0..20$/)
  end

end
