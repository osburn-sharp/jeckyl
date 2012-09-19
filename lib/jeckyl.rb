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
# The Jeckyl configurator module, which is just a wrapper. See {file:README.md Readme} for details.
#
module Jeckyl

  #default location for all config files
  ConfigRoot = '/etc/jermine'

  # This is the main Jeckyl class from which to create specific application
  # classes. For example, to create a new set of parameters, define a class as
  #
  #    class MyConfig < Jeckyl::Config
  #
  # More details are available in the {file:README.md Readme} file
  class Config < Hash

  # create a configuration hash by evaluating the parameters defined in the given config file.
  #
  # @param [String] config_file string path to a ruby file,
  # @param [Hash] opts contains the following options.
  # @option opts [Boolean] :flag_errors_on_defaults will raise exceptions from checks during default
  #  evaluation - although why is not clear, so best not to use it.
  # @option opts [Boolean] :local limits generated defaults to the direct class being evaluated
  #   and should only be set internally on this call
  # @option opts [Boolean] :relax, if set to true will not check for parameter methods but instead
  #   add unknown methods to the hash unchecked.
  #
  # If no config file is given then the hash of options returned will only have
  # the defaults defined for the given class.
  #
  #
  def initialize(config_file=nil, opts={})
    # do whatever a hash has to do
    super()
    
    flag_errors_on_defaults = opts[:flag_errors_on_defaults] || false
    local = opts[:local] || false
    @_relax = opts[:relax] || false

    # somewhere to save the most recently set symbol
    @_last_symbol = nil
    # hash for comments accessed with the same symbol
    @_comments = {}
    # hash for input defaults
    @_defaults={}
    # save order in which methods are defined for generating config files
    @_order = Array.new

    # get the defaults defined in the config parser
    get_defaults(:local=> local, :flag_errors => flag_errors_on_defaults)

    return self if config_file.nil?

    # remember where the config file itself is
    self[:config_files] = [config_file]
    
    # and finally get the values from the config file itself
    self.instance_eval(File.read(config_file), config_file)

  rescue SyntaxError => err
    raise ConfigSyntaxError, err.message
  rescue Errno::ENOENT
    # duff file path so tell the caller
    raise ConfigFileMissing, "#{config_file}"
  end

  # gives access to a hash containing an entry for each parameter and the comments
  # defined by the class definitions - used internally by class methods
  def comments
    @_comments
  end
  
  # This contains an array of the parameter names - used internally by class methods
  def order
    @_order
  end
  
  # this contains a hash of the defaults for each parameter - used internally by class methods
  def defaults
    @_defaults
  end

  # a class method to check a given config file one item at a time
  #
  # This evaluates the given config file and reports if there are any errors to the
  # report_file, which defaults to Stdout. Can only do the checking one error at a time.
  #
  # To use this method, it is necessary to write a script that calls it for the particular
  # subclass.
  #
  # @param [String] config_file is the file to check
  # @param [String] report_file is a file to write the report to, or stdout
  # @return [Boolean] indicates if the check was OK or not
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
  # This calls each of the parameter methods, and creates a commented template
  # with the comments and default lines
  #
  # @param [Boolean] local when set to true will limit the parameters to those defined in the
  #  immediate class and excludes any ancestors.
  #
  def self.generate_config(local=false)
    me = self.new(nil, :local => local)
    # everything should now exist
    me.order.each do |key|

      if me.comments.has_key?(key) then
        me.comments[key].each do |comment|
          puts "# #{comment}"
        end
      end
      def_value = me.defaults[key]
      default = def_value.nil? ? '' : def_value.inspect

      puts "##{key.to_s} #{default}"
      puts ""
    end
  end
  
  # extract only those parameters in a hash that are from the given class
  #
  # @param [Hash] full_config is the config from which to extract the intersecting options
  #  and it can be an instance of Jeckyl::Config or a hash 
  # @return [Hash] containing all of the intersecting parameters
  #
  # Note this returns a plain hash and not an instance of Jeckyl::Config
  #
  def self.intersection(full_config)
    me = self.new # create the defaults for this class
    my_hash = {}
    me.order.each do |my_key|
      if full_config.has_key?(my_key) then
        my_hash[my_key] = full_config[my_key]
      end
    end
    return my_hash
  end
  
  # return a list of descendant classes in the current context. This is provided to help
  # find classes for the jeckyl utility, e.g. to generate a default config file
  #
  # @return [Array] classes that are descendants of this class, sorted with the least ancestral
  #  first
  #
  def self.descendants
    descs = Array.new
    ObjectSpace.each_object {|obj| descs << obj if obj.kind_of?(Class) && obj < self}
    descs.sort! {|a,b| a < b ? -1 : 1}
    return descs
  end
  

  # set the prefix to the parameter names that should be used for corresponding
  # parameter methods defined for a subclass. Parameter names in config files 
  # are mapped onto parameter method by prefixing the methods with the results of
  # this function. So, for a parameter named 'greeting', the parameter method used
  # to check the parameter will be, by default, 'configure_greeting'.
  #
  # For example, to define parameter methods prefix with 'set' redefine this
  # method to return 'set'. The greeting parameter method should then be called
  # 'set_greeting'
  #
  def prefix
    'configure'
  end
  
  # Delete those parameters that are in the given hash from this instance of Jeckyl::Config.
  # Useful for tailoring parameter sets to specific uses (e.g. removing logging parameters)
  #
  # @param [Hash] conf_to_remove which is a hash or an instance of Jeckyl::Config
  #
  def complement(conf_to_remove)
    self.delete_if {|key, value| conf_to_remove.has_key?(key)}
  end
  
  # Read, check and merge another parameter file into this one, being of the same config class.
  #
  # @param [String] conf_file - path to file to parse
  #
  def merge(conf_file)
    
    self[:config_files] << conf_file
    
    # and finally get the values from the config file itself
    self.instance_eval(File.read(conf_file), conf_file)

  rescue SyntaxError => err
    raise ConfigSyntaxError, err.message
  rescue Errno::ENOENT
    # duff file path so tell the caller
    raise ConfigFileMissing, "#{conf_file}"
  end


  protected
  
  # create a description for the current parameter, to be used when generating a config template
  #
  # @param [*String] being one or more string arguments that are used to generate config file templates
  #  and documents
  def comment(*strings)
    @_comments[@_last_symbol] = strings unless @_last_symbol.nil?
  end

  # set default value(s) for the current parameter.
  #
  # @param [Object] val - any valid object as expected by the parameter method
  def default(val)
    return if @_last_symbol.nil? || @_defaults.has_key?(@_last_symbol)
    @_defaults[@_last_symbol] = val
  end

  # the following are all helper methods to parse values and raise exceptions if the values are not correct

  # file helpers - meanings should be apparent
  
  # check that the parameter is a directory and that the directory is writable
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [String] - path
  #
  def a_writable_dir(path)
    if FileTest.directory?(path) && FileTest.writable?(path) then
      path
    else
      raise_config_error(path, "directory is not writable or does not exist")
    end
  end

  # check parameter is a readable file
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [String] - path to file
  #
  def a_readable_file(path)
    if FileTest.readable?(path) then
      path
    else
      raise_config_error(path, "file does not exist")
    end
  end

  # simple type helpers

  # check the parameter is of the required type
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [Object] obj to check type of
  # @param [Class] type, being a class constant such as Numeric, String
  #
  def a_type_of(obj, type)
    if obj.kind_of?(type) then
      obj
    else
      raise_config_error(obj, "value is not of required type: #{type}")
    end
  end

  # check that the parameter is within the required range
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [Numeric] val to check
  # @param [Numeric] lower bound of range
  # @param [Numeric] upper bound of range
  #
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
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [Boolean] val to check
  #
  def a_boolean(val)
    if val.kind_of?(TrueClass) || val.kind_of?(FalseClass) then
      val
    else
      raise_config_error(val, "Value is not a Boolean")
    end
  end

  # check the parameter is a flag, being "true", "false", "yes", "no", "on", "off", or 1 , 0
  # and return a proper boolean
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [String] val to check
  #
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
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [Array] ary to check
  #
  def an_array(ary)
    if ary.kind_of?(Array) then
      ary
    else
      raise_config_error(ary, "value is not an Array")
    end
  end

  # check the parameter is an array and the array is of the required type
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [Array] ary of values to check
  # @param [Class] type being the class that the values must belong to
  #
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
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [Hash] hsh to check
  #
  def a_hash(hsh)
    if hsh.kind_of?(Hash) then
      true
    else
      raise_config_error(hsh, "value is not a Hash")
    end
  end

  # strings and text and stuff

  # check the parameter is a string
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [String] str to check
  #
  def a_string(str)
    if str.kind_of?(String) then
      str
    else
      raise_config_error(str.to_s, "is not a String")
    end
  end

  # check the parameter is a string and matches the required pattern
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [String] str to match against the pattern
  # @param [Regexp] pattern to match with
  #
  def a_matching_string(str, pattern)
    raise_syntax_error("Attempt to pattern match without a Regexp") unless pattern.kind_of?(Regexp)
    if pattern =~ a_string(str) then
      str
    else
      raise_config_error(str, "does not match required pattern: #{pattern.source}")
    end
  end

  # set membership - set is an array of members, usually symbols
  #
  # Jeckyl checking method to be used in parameter methods to check the validity of
  # given parameters, returning the parameter if valid or else raising an exception
  # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
  # the parameter is not validly formed
  #
  # @param [Symbol] symb being the symbol to check
  # @param [Array] set containing the valid symbols that symb should belong to
  #
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
  # unless @_relax then it will raise an exception. Otherwise it will create a key value pair
  #
  # This method also remembers the method name as the key to prevent the parsers etc from
  # having to carry this around just to do things like report on it.
  #
  def method_missing(symb, parameter)

    @_last_symbol = symb
    #@parameter = parameter
    method_to_call = ("#{self.prefix}_" + symb.to_s).to_sym
    set_method = self.method(method_to_call)

    self[@_last_symbol] = set_method.call(parameter)

  rescue NameError
    #raise if @@debug
    # no parser method defined.
    unless @_relax then
      # not tolerable
      raise UnknownParameter, format_error(symb, parameter, "Unknown parameter")
    else
      # feeling relaxed, so lets store it anyway.
      self[symb] = parameter
    end

  end

  # get_defaults
  #
  # calls each method with the specified prefix with no parameters so that the defaults
  # defined for each will be passed back and used to set the hash before the
  # config file is evaluated.
  #
  def get_defaults(opts={})
    flag_errors = opts[:flag_errors] 
    local = opts[:local]

    # go through all of the methods
    self.class.instance_methods(!local).each do |method_name|
      if md = /^#{self.prefix}_/.match(method_name) then

        # its a prefixed method so call it

        pref_method = self.method(method_name.to_sym)
        # get the corresponding symbol for the hash
        @_last_symbol = md.post_match.to_sym
        @_order << @_last_symbol
        # and call the method with no parameters, which will
        # call the comment method and the default method where defined
        # and thereby capture their values
        begin
          a_value = pref_method.call(1)
        rescue Exception
          # ignore any errors, which are bound to result from passing in 1
        end
        begin
          # now set the actual default by calling the method again and passing
          # the captured default, providing a result which may be different if the method transforms
          # the parameter!
          param = @_defaults[@_last_symbol]
          self[@_last_symbol] = pref_method.call(param) unless param.nil?
        rescue Exception
          raise if flag_errors
          # ignore any errors raised
        end
      end
    end
  end

  # really private helpers that should not be needed unless the parser method
  # is custom
  
  protected

  # helper method to format exception messages. A config error should be raised
  # when the given parameter does not match the checks.
  #
  # The exception is raised in the caller's context to ensure backtraces are accurate.
  #
  # @param [Object] value - the object that caused the error
  # @param [String] message to include in the exception
  #
  def raise_config_error(value, message)
    raise ConfigError, format_error(@_last_symbol, value, message), caller
  end

  # helper method to format exception messages. A syntax error should be raised
  # when the check method has been used incorrectly. See check methods for examples.
  #
  # The exception is raised in the caller's context to ensure backtraces are accurate.
  #
  # @param [String] message to include in the exception
  #
  def raise_syntax_error(message)
    raise ConfigSyntaxError, message, caller
  end

  # helper method to format an error
  def format_error(key, value, message)
    "[#{key}]: #{value} - #{message}"
  end

  end
  
  # define an alias for backwards compatitbility
  # @deprecated Please use Jeckyl::Config
  Options = Config

end

