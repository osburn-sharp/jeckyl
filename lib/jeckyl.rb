#
# Author:: Robert Sharp
# Copyright:: Copyright (c) 2011 Robert Sharp
# License:: Open Software Licence v3.0
#
# This software is licensed for use under the Open Software Licence v. 3.0
# The terms of this licence can be found at http://www.opensource.org/licenses/osl-3.0.php
# and in the file copyright.txt. Under the terms of this licence, all derivative works
# must themselves be licensed under the Open Software Licence v. 3.0
#
#
# == JECKYL
#
require 'jeckyl/version'
require 'jeckyl/errors'

#
# main configurator class. You can either create an instance of this class and use it in
# relaxed mode, or create a subclass in which to define various parsing methods. See README
# for more details of usage.
#
module Jeckyl

  #default location for all config files
  ConfigRoot = '/etc/jermine'

  class Options < Hash

  # set this to false if you want unknown methods to be turned into key value pairs regardless
  @@strict = true

  # may be useful?
  @@debug = false

  # create a configuration object
  #
  # The config_file is a string path to a ruby config file that will be evaluated and converted into
  # key value pairs
  #
  # opts is an optional hash of default key value pairs used to fill the hash before the config_file is
  # evaluated. Any values defined by the config file will overwrite these defaults.
  #
  def initialize(config_file=nil, opts={}, ignore_errors_on_default=false)
    # do whatever a hash has to do
    super()

    # somewhere to save the most recently set symbol
    @last_symbol = nil
    # hash for comments accessed with the same symbol
    @comments = {}
    # hash for input defaults
    @defaults={}
    # save order in which methods are defined for generating config files
    @order = Array.new

    # get the defaults defined in the config parser
    get_defaults(ignore_errors_on_default)

    return self if config_file.nil?

    # now add/override with whatever was passed in
    opts.each_pair do |key, value|
      self[key] = value
    end
    # and finally get the values from the config file itself
    self.instance_eval(File.read(config_file), config_file)

  rescue SyntaxError => err
    raise ConfigSyntaxError, err.message
  rescue Errno::ENOENT
    # duff file path so tell the caller
    raise ConfigFileMissing, "#{config_file}"
  end

  attr_reader :comments, :order, :defaults

  # return the current version
  def version
    Version
  end

  # set the current parameter, a convenience method that uses @last_symbol
  #  def set_param(value)
  #    self[@last_symbol] = value
  #  end

  # accept undefined parameters and add them to the hash
  def self.relax
    @@strict = false
  end

  # reset to default strict behaviour. Not really needed (unless there are multiple files)
  # but useful perhaps for testing
  def self.strict
    @@strict = true
  end

  def self.debug=(val)
    @@debug = (val)
  end

  # a class method to check a given config file one item at a time
  #
  # This evaluates the given config file and reports if there are any errors to the
  # report_file, which defaults to Stdout. Can only do the checking one error at a time.
  #
  # To use this method, it is necessary to write a script that calls it for the particular
  # subclass.
  #
  def self.check_config(config_file, report_file=nil)

    # create myself to generate defaults, but nothing else
    me = self.new

    success = true
    message = "No errors found in: #{config_file}"

    begin
      # evaluate the config file
      me.instance_eval(File.read(config_file), config_file)

    rescue Errno::ENOENT
      message = "No such config file: #{config_file}"
      success = false
    rescue JeckylError => err
      message = err.message
      success = false
    rescue SyntaxError => err
      message = err.message
      success = false
    end

    begin
      if report_file.nil? then
        puts message
      else
        File.open(report_file, "w") do |rfile|
          rfile.puts message
        end
      end
      return success
    rescue Errno::ENOENT
      raise ReportFileError, "Error with file: #{report_file}"
    end

  end

  # a class method to generate a config file from the class definition
  #
  # This calls each of the set_ methods, as in get_defaults, and creates a commented template
  # with the descriptions and default lines
  #
  def self.generate_config(cfile=$stdout)
    me = self.new
    # everything should now exist
    me.order.each do |key|

      if me.comments.has_key?(key) then
        me.comments[key].each do |comment|
          cfile.puts "# #{comment}"
        end
      end
      def_value = me.defaults[key]

      # seems to need to be converted to a string to work here
      default = case def_value.class.to_s
      when "String"
        '"' + def_value + '"'
      when "Symbol"
        ":#{def_value}"
      else
        "#{def_value}"
      end
      cfile.puts "##{key.to_s} #{default}"
      cfile.puts ""
    end
  end

  # set the prefix to the parameter names that should be used for corresponding
  # configure methods defined for a subclass.
  #
  # For example, parameter log_rotation will call configure_log_rotation by default
  # unless the subclass defines this method differently
  #
  def prefix
    'configure'
  end


  protected

  # create a description for the current parameter, to be used when generating a config template
  def comment(*strings)
    @comments[@last_symbol] = strings unless @last_symbol.nil?
  end

  # set default value(s) for the current parameter.
  #
  def default(val)
    return if @last_symbol.nil? || @defaults.has_key?(@last_symbol)
    @defaults[@last_symbol] = val
  end

  # the following are all helper methods to parse values and raise exceptions if the values are not correct

  # file helpers - meanings should be apparent

  # check that the parameter is a directory and that the directory is writable
  def a_writable_dir(path)
    if FileTest.directory?(path) && FileTest.writable?(path) then
      path
    else
      raise_config_error(path, "directory is not writable or does not exist")
    end
  end

  # check parameter is a readable file
  def a_readable_file(path)
    if FileTest.readable?(path) then
      path
    else
      raise_config_error(path, "file does not exist")
    end
  end

  # simple type helpers

  # check the parameter is of the required type
  def a_type_of(obj, type)
    if obj.kind_of?(type) then
      obj
    else
      raise_config_error(obj, "value is not of required type: #{type}")
    end
  end

  # check that the parameter is within the required range
  def in_range(val, lower, upper)
    raise_syntax_error("#{lower.to_s}..#{upper.to_s} is not a range") unless (lower .. upper).kind_of?(Range)
    if (lower .. upper) === val then
      val
    else
      raise_config_error(val, "value is not within required range: #{lower.to_s}..#{upper.to_s}")
    end
  end


  # boolean helpers

  # check parameter is a boolean, true or false but not strings "true" or "false"
  def a_boolean(val)
    if val.kind_of?(TrueClass) || val.kind_of?(FalseClass) then
      val
    else
      raise_config_error(val, "Value is not a Boolean")
    end
  end

  # check the parameter is a flag, being "true", "false", "yes", "no", "on", "off", or 1 , 0
  # and return a proper boolean
  def a_flag(val)
    val = val.downcase if val.kind_of?(String)
    case val
    when "true", "yes", "on", 1
      true
    when "false", "no", "off", 0
      false
    else
      raise_config_error(val, "Cannot convert to Boolean")
    end
  end


  # compound objects

  # check the parameter is an array
  def an_array(ary)
    if ary.kind_of?(Array) then
      ary
    else
      raise_config_error(ary, "value is not an Array")
    end
  end

  # check the parameter is an array and the array is of the required type
  def an_array_of(ary, type)
    raise_syntax_error("Provided a value that is a type: #{type.to_s}") unless type.class == Class
    if ary.kind_of?(Array) then
      ary.each do |element|
        unless element.kind_of?(type) then
          raise_config_error(element, "element of array is not of type: #{type}")
        end
      end
      return ary
    else
      raise_config_error(ary, "value is not an Array")
    end
  end

  # check the parameter is a hash
  def a_hash(hsh)
    if hsh.kind_of?(Hash) then
      true
    else
      raise_config_error(hsh, "value is not a Hash")
    end
  end

  # strings and text and stuff

  # check the parameter is a string
  def a_string(str)
    if str.kind_of?(String) then
      str
    else
      raise_config_error(str.to_s, "is not a String")
    end
  end

  # check the parameter is a string and matches the required pattern
  def a_matching_string(str, pattern)
    raise_syntax_error("Attempt to pattern match without a Regexp") unless pattern.kind_of?(Regexp)
    if pattern =~ a_string(str) then
      str
    else
      raise_config_error(str, "does not match required pattern: #{pattern.source}")
    end
  end

  # set membership - set is an array of members, usually symbols
  def a_member_of(symb, set)
    raise_syntax_error("Sets to test membership must be arrays") unless set.kind_of?(Array)
    if set.include?(symb) then
      symb
    else
      raise_config_error(symb, "is not a member of: #{set.join(', ')}")
    end
  end


  private

  # decides what to do with parameters that have not been defined.
  # if @@strict then it will raise an exception. Otherwise it will create a key value pair
  #
  # This method also remembers the method name as the key to prevent the parsers etc from
  # having to carry this around just to do things like report on it.
  #
  def method_missing(symb, parameter)

    @last_symbol = symb
    #@parameter = parameter
    method_to_call = ("#{self.prefix}_" + symb.to_s).to_sym
    set_method = self.method(method_to_call)

    self[@last_symbol] = set_method.call(parameter)

  rescue NameError
    raise if @@debug
    # no parser method defined.
    if @@strict then
      # not tolerable
      raise UnknownParameter, format_error(symb, parameter, "Unknown parameter")
    else
      # feeling relaxed, so lets store it anyway.
      self[symb] = parameter
    end

  end

  # get_defaults
  #
  # calls each method with the name set_* with no parameters so that the defaults
  # defined for each will be passed back and used to set the hash before the
  # config file is evaluated.
  #
  def get_defaults(ignore_errors)

    # go through all of the methods
    self.methods.each do |method_name|
      if md = /^#{self.prefix}_/.match(method_name) then

        # its a set_ method so call it

        set_method = self.method(method_name.to_sym)
        # get the corresponding symbol for the hash
        @last_symbol = md.post_match.to_sym
        @order << @last_symbol
        # and call the method with no parameters
        begin
          a_value = set_method.call(1)
        rescue Exception
          # ignore any errors
        end
        begin
          # now set the actual default from calling the method
          # which may be different if the method transforms
          # the parameter!
          param = @defaults[@last_symbol]
          self[@last_symbol] = set_method.call(param) unless param.nil?
        rescue Exception
          raise unless ignore_errors
          # ignore any errors
        end
      end
    end
  end

  # really private helpers that should not be needed unless the parser method
  # is custom

  def raise_config_error(value, message)
    raise ConfigError, format_error(@last_symbol, value, message), caller
  end

  def raise_syntax_error(message)
    raise ConfigSyntaxError, message, caller
  end

  def format_error(key, value, message)
    "[#{key}]: #{value} - #{message}"
  end

  end

end