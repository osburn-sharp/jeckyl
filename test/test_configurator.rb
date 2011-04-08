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
    set_param(path) if is_writable_dir?(path)
  end

  def key_file(path)
    set_param(path) if is_readable_file?(path)
  end

  def set_log_level(symb)
    symbol_set = [:system, :verbose, :debug]
    set_param(symb) if is_member_of?(symb, symbol_set)
  end

  def set_log_rotation(val)
    set_param(val) if is_of_type?(val, Integer) && is_in_range?(val, 0, 20)
  end

  def set_threshold(val)
    set_param(val) if is_in_range?(val, 0.0, 10.0)
  end

  def set_pi(val)
    set_param(val) if is_of_type?(val, Float)
  end

  def set_sieve(ary)
    set_param(ary) if is_array_of?(ary, Integer)
  end

  def set_options(opts)
    set_param(opts) if is_hash?(opts)
  end

  def set_email(email)
    set_param(email) if matches?(email, /^[a-z]+\@[a-z][a-z\-\.]+[a-z]$/)
  end

end