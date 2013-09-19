#
#
# = Jeckyl Helpers
#
# == Test methods for parameters
#
# Author:: Robert Sharp
# Copyright:: Copyright (c) 2013 Robert Sharp
# License:: Open Software Licence v3.0
#
# This software is licensed for use under the Open Software Licence v. 3.0
# The terms of this licence can be found at http://www.opensource.org/licenses/osl-3.0.php
# and in the file copyright.txt. Under the terms of this licence, all derivative works
# must themselves be licensed under the Open Software Licence v. 3.0
#
# 
#

module Jeckyl
  
  module Helpers
    
    # the following are all helper methods to parse values and raise exceptions if the values are not correct
    
    # file helpers - meanings should be apparent
    
    # check that the parameter is a directory and that the directory is writable
    #
    # Jeckyl checking method to be used in parameter methods to check the validity of
    # given parameters, returning the parameter if valid or else raising an exception
    # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
    # the parameter is not validly formed
    #
    # @param [String] path to directory
    #
    def a_writable_dir(path)
      if FileTest.directory?(path) && FileTest.writable?(path) then
        path
      else
        raise_config_error(path, "directory is not writable or does not exist")
      end
    end
    
    # check that the directory is at least readable
    #
    # Jeckyl checking method to be used in parameter methods to check the validity of
    # given parameters, returning the parameter if valid or else raising an exception
    # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
    # the parameter is not validly formed
    #
    # @param [String] path to the directory to be checked
    def a_readable_dir(path)
      if FileTest.directory?(path) && FileTest.readable?(path) then
        path
      else
        raise_config_error(path, "directory is not readable or does not exist")
      end
    end
    
    # check parameter is a readable file
    #
    # Jeckyl checking method to be used in parameter methods to check the validity of
    # given parameters, returning the parameter if valid or else raising an exception
    # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
    # the parameter is not validly formed
    #
    # @param [String] path to file
    #
    def a_readable_file(path)
      if FileTest.readable?(path) then
        path
      else
        raise_config_error(path, "file does not exist")
      end
    end
    
    # check parameter is an executable file
    #
    # Jeckyl checking method to be used in parameter methods to check the validity of
    # given parameters, returning the parameter if valid or else raising an exception
    # which is either ConfigError if the parameter fails the check or ConfigSyntaxError if
    # the parameter is not validly formed
    #
    # @param [String] path to executable
    #
    def an_executable(path)
      a_readable_file(path)
      if FileTest.executable?(path) then
        path
      else
        raise_config_error(path, "file is not executable")
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
    # @param [Class] type being a class constant such as Numeric, String
    #
    def a_type_of(obj, type)
      if obj.kind_of?(type) then
        obj
      else
        raise_config_error(obj, "value is not of required type: #{type}")
      end
    end
    
    # number helpers
    
    # check the parameter is a number
    #
    # @param [Numeric] numb to check
    def a_number(numb)
      return numb if numb.kind_of?(Numeric)
      raise_config_error numb, "value is not a number: #{numb}"
    end
    
    # check the parameter is a positive number (or zero)
    #
    # @param [Numeric] numb to check
    def a_positive_number(numb)
      return numb if numb.kind_of?(Numeric) && numb >= 0
      raise_config_error numb, "value is not a positive number: #{numb}"
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
        hsh
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
        
    
  end
  
end