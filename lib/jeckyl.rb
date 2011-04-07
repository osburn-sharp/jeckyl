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
# === Jumpin' Ermine's Configurator for Kwit and easY Linux services
#
#

class Jeckyl

  # set this to false if you want unknown methods to be turned into key value pairs regardless
  @@strict = true

  # create a configuration object
  #
  # The config_file is a string path to a ruby config file that will be evaluated and converted into
  # key value pairs
  #
  # opts is an optional hash of defaul key value pairs
  #
  def initialize(config_file, opts={})
    @values = opts
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
  def method_missing(symb, parameter)
    if @@strict then
      raise UnknownParameter, format_error(symb, parameter, "Unknown parameter")
    else
      @values[symb] = parameter
    end
  end

  # access parameters that have been set.
  def [](key)
    @values[key]
  end


private

  # the following are all helper methods to parse values and raise exceptions if the values are not correct

  # file helpers

  def set_writable_dir(key, path)
    if FileTest.directory?(path) && FileTest.writable?(path) then
      @values[key] = path
    else
      raise_config_error(key, path, "directory is not writable or does not exist")
    end
  end

  def set_file_path(key, path)
    if FileTest.exists?(path) then
      @values[key] = path
    else
      raise_config_error(key, path, "file does not exist")
    end
  end

  # simple type helpers

  # generic method to be used by specific methods
  def matches_scalar(key, val, lower, upper=nil)
    num_class = lower.class == Class ? lower : lower.class
    unless val.kind_of?(num_class) then
      raise_config_error(key, val, "value is not of required type: #{num_class}")
    end
    if upper then
      num_class = (lower .. upper)
    end
    unless num_class === val then
      raise_config_error(key, val, "value is not an within required range: #{num_class}")
    end
    return true
  end

  def set_integer(key, val)
    @values[key] = val if matches_scalar(key, val, Integer)
  end

  def set_scalar_range(key, val, lower, upper)
    @values[key] = val if matches_scalar(key, val, lower, upper)
  end

  def set_float(key, val)
    @values[key] = val if matches_scalar(key, val, Float)
  end

  def select_symbol_set(key, symb, set)
    if set.include?(symb) then
      @values[key] = symb
    end
  end




  def raise_config_error(key, value, message)
    raise ConfigError, format_error(key, value, message), caller
  end

  def format_error(key, value, message)
    "[#{key}]: #{value} - #{message}"
  end
  
end