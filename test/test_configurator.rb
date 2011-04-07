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
  
  def log_dir(path)
    set_writable_dir(:log_dir, path)
  end

  def log_level(symb)
    symbol_set = [:system, :verbose, :debug]
    select_symbol_set(:log_level, symb, symbol_set)
  end

  def log_rotation(val)
    set_scalar_range(:log_rotation, val, 0, 20)
  end

  def threshold(val)
    set_scalar_range(:threshold, val, 0.0, 10.0)
  end

  def pi(val)
    set_float(:pi, val)
  end

end