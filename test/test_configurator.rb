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
#require 'jeckyl'

class TestJeckyl < Jeckyl::Options

  def prefix
    'set'
  end
  
  def set_log_dir(path)
    describe 'Directory for log files'
    default '/tmp'
    comment "Writable directory where the app can keep log files"
    
    option '-l', '--log-dir [PATH]', String
    
    a_writable_dir(path)
  end

  def set_key_file(path)
    describe "key file to be used to check secure commands"
    
    option '-k', '--key-file [PATH]', String
    a_readable_file(path)
  end

  def set_log_level(symb)
    default :verbose
    
    describe 'Applications logging level'
    comment "Log level can one of the following:",
       "",
       " * :system - log all important messages and use syslog",
       " * :verbose - be more generous with logging to help resolve problems"
    
    symbol_set = [:system, :verbose, :debug]
    
    option '-L', '--level [SYMBOL]', symbol_set
    
    a_member_of(symb, symbol_set)
  end

  def set_log_rotation(val)
    default 5
    a_number(val) && a_type_of(val, Integer) && in_range(val, 0, 20)
    return val
  end

  def set_threshold(val)
    describe "Threshold for things"
    default 5.0
    
    option '-T', '--threshold [NUMBER]', Numeric
    
    # make sure it is a number
    a_type_of(val, Numeric)
    # now make sure it is a float
    in_range(val.to_f, 0.0, 10.0)

  end
  
  def set_start_day(day)
    describe "Day of the week to start from"
    default 5
    comment "Can be any number from 1 to 7"
    
    a_number(day) && in_range(day, 1, 7)
    
  end
  
  def set_offset(ofs)
    describe "Offset from today to previous record"
    default 1
    comment "days from today to study"
    
    a_positive_number(ofs)
    
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

  def set_option_set(opts)
    default Hash.new
    a_hash(opts)
  end

  def set_email(email)
    default "me@home.org.uk"
    a_matching_string(email, /^[a-z]+\@[a-z][a-z\-\.]+[a-z]$/)
  end

#  def set_invalid_set(member)
#    default 1
#    invalid_set = {:one=>1, :two=>2, :three=>3}
#    a_member_of(member, invalid_set)
#  end
#
#  def set_invalid_pattern(email)
#    default "me@work.org.uk"
#    pattern = "email"
#    a_matching_string(email, pattern)
#  end

end