#
#
# = Jeckyl Service
#
# == configuration options for Jerbil Services
#
# Author:: Robert Sharp
# Copyright:: Copyright (c) 2012 Robert Sharp
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

module Jeckyl
  
  # inherit from this class to include the following options automatically in
  # you config file. These options are expected for a Jerbil::Service class.
  #
  # check the comment calls below for details
  #
  class Service < Jeckyl::Options
    
    def configure_environment(env)
        default :prod
        comment "Set the default environment for service commands etc.",
          "",
          "Can be one of :prod, :test, :dev"

        env_set = [:prod, :test, :dev]
        a_member_of(env, env_set)

    end

    def configure_log_dir(dir)
      default '/var/log/jermine'
      comment "Location for Jelly (logging utility) to save log files"

      a_writable_dir(dir)

    end

    def configure_key_dir(dir)
      default '/var/run/jermine'
      comment "Location to store the supervisor key used to control the service"

      a_writable_dir(dir)
    end

    def configure_pid_dir(dir)
      default '/var/run/jermine'
      comment "Location to store the service pid"

      a_writable_dir(dir)
    end

    
    # options relating to the use of a logger

    def configure_log_level(lvl)
      default :system
      comment "Controls the amount of logging done by Jelly",
        "",
        " * :system - standard message, plus log to syslog",
        " * :verbose - more generous logging to help resolve problems",
        " * :debug - usually used only for resolving problems during development",
        ""

      lvl_set = [:system, :verbose, :debug]
      a_member_of(lvl, lvl_set)

    end

    # log_rotation === 0..20 files
    def configure_log_rotation(int)
      default 2
      comment "Number of log files to retain at any time"

      a_type_of(int, Integer) && in_range(int, 0, 20)

    end

    # log_length === 1..20 Mb
    def configure_log_length(int)
      default 1 #Mbyte
      comment "Size of a log file (in MB) before switching to the next log"

      a_type_of(int, Integer) && in_range(int, 1, 20)
      @parameter = int * 1024 * 1024
    end 
    
    def configure_user(name)
      comment "Provide the name of the user under which this process should run",
        "being a valid user name for the current system. If not provided, the",
        "application will not attempt to change user id"
      
      a_type_of(name, String)
    end
    
    def configure_exit_on_stop(bool)
      default true
      comment "Boolean - set to false to prevent service from executing exit! on stop"

      a_boolean(bool)
    end
    
    
  end
end