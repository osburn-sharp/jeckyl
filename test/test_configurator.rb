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

class TestJeckyl < Jeckyl
  
  def set_log_dir(path)
    is_writable_dir?(path)
  end

  def set_key_file(path)
    is_readable_file?(path)
  end

  def set_log_level(symb)
    symbol_set = [:system, :verbose, :debug]
    is_member_of?(symb, symbol_set)
  end

  def set_log_rotation(val)
    is_of_type?(val, Integer) && is_in_range?(val, 0, 20)
  end

  def set_threshold(val)
    # make sure it is a number
    is_of_type?(val, Numeric)
    # now make sure it is a float
    @parameter = val.to_f
    is_in_range?(val, 0.0, 10.0)
  end

  def set_pi(val)
    is_of_type?(val, Float)
  end

  def set_debug(bool)
    is_boolean?(bool)
  end

  def set_flag(flag)
    @parameter = to_boolean(flag)
  end

  def set_collection(ary)
    is_array?(ary)
  end
  
  def set_sieve(ary)
    is_array_of?(ary, Integer)
  end

  def set_options(opts)
    is_hash?(opts)
  end

  def set_email(email)
    matches?(email, /^[a-z]+\@[a-z][a-z\-\.]+[a-z]$/)
  end

  def set_invalid_set(member)
    invalid_set = {:one=>1, :two=>2, :three=>3}
    is_member_of?(member, invalid_set)
  end

  def set_invalid_pattern(email)
    pattern = "email"
    matches?(email, pattern)
  end

end