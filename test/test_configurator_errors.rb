#
# Description
#
# Author:: Robert Sharp
# Copyright:: Copyright (c) 2010 Robert Sharp
# License:: Open Software Licence v3.0
#
# This software is licensed for use under the Open Software Licence v. 3.0
# The terms of this licence can be found at http://www.opensource.org/licenses/osl-3.0.php
# and in the file copyright.txt. Under the terms of this licence, all derivative works
# must themselves be licensed under the Open Software Licence v. 3.0
# 
#
require 'jeckyl'

class TestJeckylErrors < Jeckyl::Options

  def prefix
    'set'
  end
  
  def set_log_dir(path)
    default '/tmp'
    comment "Location to write log files to"
    a_writable_dir(path)
  end

  def set_key_file(path)
    comment "key file to be used to check secure commands"
    a_readable_file(path)
  end

  def set_log_level(symb)
    default :verbose
    comment "Log level can one of the following:",
       "",
       " * :system - log all important messages and use syslog",
       " * :verbose - be more generous with logging to help resolve problems"
    symbol_set = [:system, :verbose, :debug]
    a_member_of(symb, symbol_set)
  end

  def set_log_rotation(val)
    default 5
    a_type_of(val, Integer)
    in_range(val, 0, 20)
  end

  def set_threshold(val)
    default 5.0
    # make sure it is a number
    a_type_of(val, Numeric)
    # now make sure it is a float
    in_range(val.to_f, 0.0, 10.0)

  end

  def set_pi(val)
    default 3.14
    a_type_of(val, Float)
  end

  def set_debug(bool)
    default false
    a_boolean(bool)
  end

  def set_flag(flag)
    default "on"
    a_flag(flag)
  end

  def set_collection(ary)
    default Array.new
    an_array(ary)
  end
  
  def set_sieve(ary)
    default [1,2,3]
    an_array_of(ary, Integer)
  end

  def set_options(opts)
    default Hash.new
    a_hash(opts)
  end

  def set_email(email)
    default "me@home.org.uk"
    a_matching_string(email, /^[a-z]+\@[a-z][a-z\-\.]+[a-z]$/)
  end

  def set_invalid_set(member)
    default 1
    invalid_set = {:one=>1, :two=>2, :three=>3}
    a_member_of(member, invalid_set)
  end

  def set_invalid_pattern(email)
    default "me@work.org.uk"
    pattern = "email"
    a_matching_string(email, pattern)
  end

end