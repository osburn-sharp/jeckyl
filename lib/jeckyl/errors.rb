#
# Description
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

class Jeckyl

  # A standard class for all Jeckyl exceptions
  class JeckylError < Exception; end

  # the config file given does not exist
  class ConfigFileMissing < JeckylError; end

  # the config file has a syntax error
  class ConfigSyntaxError < JeckylError; end

  # a config parameter was incorrect
  class ConfigError < JeckylError; end

  # the given config parameter is not known
  class UnknownParameter < JeckylError; end

  # could not open the specified report file
  class ReportFileError < JeckylError; end

end
