#
#
# = Title
#
# == SubTitle
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
#

require 'jeckyl'

class Aclass < Jeckyl::Options
  
  def configure_a_bool(bool)
    default true
    a_boolean(bool)
  end
  
  def configure_no_def(text)
    a_string(text)
  end
  
end