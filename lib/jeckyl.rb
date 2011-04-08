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

#
# main configurator class. You can either create an instance of this class and use it in
# relaxed mode, or create a subclass in which to define various parsing methods. See README
# for more details of usage.
#
class Jeckyl < Hash

  # set this to false if you want unknown methods to be turned into key value pairs regardless
  @@strict = true

  # create a configuration object
  #
  # The config_file is a string path to a ruby config file that will be evaluated and converted into
  # key value pairs
  #
  # opts is an optional hash of default key value pairs used to fill the hash before the config_file is
  # evaluated. Any values defined by the config file will overwrite these defaults.
  #
  def initialize(config_file, opts={})
    super()
    opts.each_pair do |key, value|
      self[key] = value
    end
    self.instance_eval(File.read(config_file), config_file)
  rescue SyntaxError => err
    raise ConfigSyntaxError, err.message
  rescue Errno::ENOENT
    # duff file path so tell the caller
    raise ConfigFileMissing, "#{config_file}"
  end

  # decides what to do with parameters that have not been defined.
  # if @@strict then it will raise an exception. Otherwise it will create a key value pair
  #
  # This method also remembers the method name as the key to prevent the parsers etc from
  # having to carry this around just to do things like report on it.
  #
  def method_missing(symb, parameter)

    @last_symbol = symb
    method_to_call = ('set_' + symb.to_s).to_sym
    set_method = self.method(method_to_call)
    set_method.call(parameter)

  rescue NameError
    # no parser method defined.
    if @@strict then
      # not tolerable
      raise UnknownParameter, format_error(symb, parameter, "Unknown parameter")
    else
      # feeling relaxed, so lets store it anyway.
      self[symb] = parameter
    end
    
  end

  # set the current parameter, a convenience method that uses @last_symbol
  def set_param(value)
    self[@last_symbol] = value
  end

  # accept undefined parameters and add them to the hash
  def self.relax
    @@strict = false
  end

  # reset to default strict behaviour. Not really needed (unless there are multiple files)
  # but useful perhaps for testing
  def self.strict
    @@strict = true
  end

private

  # the following are all helper methods to parse values and raise exceptions if the values are not correct

  # file helpers - meanings should be apparent

  def is_writable_dir?(path)
    if FileTest.directory?(path) && FileTest.writable?(path) then
      true
    else
      raise_config_error(path, "directory is not writable or does not exist")
    end
  end

  def is_readable_file?(key, path)
    if FileTest.readable?(path) then
      true
    else
      raise_config_error(path, "file does not exist")
    end
  end

  # simple type helpers

  def is_of_type?(val, type)
    if val.kind_of?(type) then
      true
    else
      raise_config_error(val, "value is not of required type: #{type}")
    end
  end
  
  def is_in_range?(val, lower, upper)
    raise_syntax_error("#{lower.to_s}..#{upper.to_s} is not a range") unless (lower .. upper).kind_of?(Range)
    if (lower .. upper) === val then
      true
    else
      raise_config_error(val, "value is not an within required range: #{lower.to_s}..#{upper.to_s}")
    end
  end


  # boolean helpers

  def is_boolean?(val)
    if val.kind_of?(Boolean) then
      true
    else
      raise_config_error(val, "Value is not a Boolean")
    end
  end

  # accept yes/no, on/off, etc
  def to_boolean(val)
    val = val.downcase if val.kind_of?(String)
    case val
    when true, "yes", "on", 1
      true
    when false, "no", "off", 0
      false
    else
      raise_config_error(val, "Cannot convert to Boolean")
    end
  end


  # compound objects

  def is_array?(ary)
    if ary.kind_of?(Array) then
      true
    else
      raise_config_error(ary, "value is not an Array")
    end
  end

  def is_array_of?(ary, type)
    raise_syntax_error("Provided a value that is a type: #{type.to_s}") unless type.class == Class
    if ary.kind_of?(Array) then
      ary.each do |element|
        unless element.kind_of?(type) then
          raise_config_error(element, "element of array is not of type #{type}")
        end
      end
      return true
    else
      raise_config_error(ary, "value is not an Array")
    end
  end

  def is_hash?(hsh)
    if hsh.kind_of?(Hash) then
      true
    else
      raise_config_error(hsh, "value is not a Hash")
    end
  end

  # strings and text and stuff

  def is_a_string?(str)
    if str.kind_of?(String) then
      true
    else
      raise_config_error(str, "is not a string")
    end
  end

  def matches?(str, pattern)
    raise_syntax_error("Attempt to pattern match with out a Regexp") unless pattern.kind_of?(Regexp)
    if pattern =~ str then
      true
    else
      raise_config_error(str, "does not match required pattern: #{pattern.source}")
    end
  end

  # set membership - set is an array of members

  def is_member_of?(symb, set)
    raise_syntax_error("Sets to test membership must be arrays") unless set.kind_of?(Array)
    if set.include?(symb) then
      true
    else
      raise_config_error(symb, "is not a member of: #{set.join(', ')}")
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