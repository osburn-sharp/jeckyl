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
require 'optparse'
require 'jeckyl/version'
require 'jeckyl/errors'
require 'jeckyl/helpers'

#
# The Jeckyl configurator module, which is just a wrapper. See {file:README.md Readme} for details.
#
module Jeckyl

  #default location for all config files
  # @deprecated Use {Jeckyl.config_dir} instead
  ConfigRoot = '/etc/jerbil'
  
  # the default system location for jeckyl config file
  # 
  # This location can be set with the environment variable JECKYL_CONFIG_DIR
  def Jeckyl.config_dir
    ENV['JECKYL_CONFIG_DIR'] || '/etc/jerbil'
  end

  # This is the main Jeckyl class from which to create specific application
  # classes. For example, to create a new set of parameters, define a class as
  #
  #    class MyConfig < Jeckyl::Config
  #
  # More details are available in the {file:README.md Readme} file
  class Config < Hash
    

    # create a configuration hash by evaluating the parameters defined in the given config file.
    #
    # @param [String] config_file string path to a ruby file,
    # @param [Hash] opts contains the following options.
    # @option opts [Boolean] :flag_errors_on_defaults will raise exceptions from checks during default
    #  evaluation - although why is not clear, so best not to use it.
    # @option opts [Boolean] :local limits generated defaults to the direct class being evaluated
    #   and should only be set internally on this call
    # @option opts [Boolean] :relax, if set to true will not check for parameter methods but instead
    #   add unknown methods to the hash unchecked.
    #
    # If no config file is given then the hash of options returned will only have
    # the defaults defined for the given class.
    #
    #
    def initialize(config_file=nil, opts={})
      # do whatever a hash has to do
      super()
      
      flag_errors_on_defaults = opts[:flag_errors_on_defaults] || false
      local = opts[:local] || false
      @_relax = opts[:relax] || false
    
      # somewhere to save the most recently set symbol
      @_last_symbol = nil
      # hash for comments accessed with the same symbol
      @_comments = {}
      # hash for input defaults
      @_defaults = {}
      # hash for optparse options
      @_options = {}
      # hash for short descriptions
      @_descriptions = {}
      # save order in which methods are defined for generating config files
      @_order = Array.new
    
      # get the defaults defined in the config parser
      get_defaults(:local=> local, :flag_errors => flag_errors_on_defaults)
      
      self[:config_files] = Array.new
    
      return self if config_file.nil?
    
      # remember where the config file itself is
      self[:config_files] = [config_file]
      
      # and finally get the values from the config file itself
      self.instance_eval(File.read(config_file), config_file)
    
    rescue SyntaxError => err
      raise ConfigSyntaxError, err.message
    rescue Errno::ENOENT
      # duff file path so tell the caller
      raise ConfigFileMissing, "#{config_file}"
    end
    
    # gives access to a hash containing an entry for each parameter and the comments
    # defined by the class definitions - used internally by class methods
    def _comments
      @_comments
    end
    
    # This contains an array of the parameter names - used internally by class methods
    def _order
      @_order
    end
    
    # this contains a hash of the defaults for each parameter - used internally by class methods
    def _defaults
      @_defaults
    end
    
    # return hash of options - used internally to generate files etc
    def _options
      @_options
    end
    
    # return has of descriptions
    def _descriptions
      @_descriptions
    end
    
    # a class method to check a given config file one item at a time
    #
    # This evaluates the given config file and reports if there are any errors to the
    # report_file, which defaults to Stdout. Can only do the checking one error at a time.
    #
    # To use this method, it is necessary to write a script that calls it for the particular
    # subclass.
    #
    # @param [String] config_file is the file to check
    # @param [String] report_file is a file to write the report to, or stdout
    # @return [Boolean] indicates if the check was OK or not
    #
    def self.check_config(config_file, report_file=nil)
    
      # create myself to generate defaults, but nothing else
      me = self.new
    
      success = true
      message = "No errors found in: #{config_file}"
    
      begin
        # evaluate the config file
        me.instance_eval(File.read(config_file), config_file)
    
      rescue Errno::ENOENT
        message = "No such config file: #{config_file}"
        success = false
      rescue JeckylError => err
        message = err.message
        success = false
      rescue SyntaxError => err
        message = err.message
        success = false
      end
    
      begin
        if report_file.nil? then
          puts message
        else
          File.open(report_file, "w") do |rfile|
            rfile.puts message
          end
        end
        return success
      rescue Errno::ENOENT
        raise ReportFileError, "Error with file: #{report_file}"
      end
    
    end
    
    # a class method to generate a config file from the class definition
    #
    # This calls each of the parameter methods, and creates a commented template
    # with the comments and default lines
    #
    # @param [Boolean] local when set to true will limit the parameters to those defined in the
    #  immediate class and excludes any ancestors.
    #
    def self.generate_config(local=false)
      me = self.new(nil, :local => local)
      # everything should now exist
      me._order.each do |key|
        
        if me._descriptions.has_key?(key) then
          puts "# #{me._descriptions[key]}"
          puts "#"
        end
    
        if me._comments.has_key?(key) then
          me._comments[key].each do |comment|
            puts "# #{comment}"
          end
        end
        # output an option description if needed
        if me._options.has_key?(key) then
          puts "#"
          puts "# Optparse options for this parameter:"
          puts "#  #{me._options[key].join(", ")}"
          puts "#"
        end
        def_value = me._defaults[key]
        default = def_value.nil? ? '' : def_value.inspect
    
        puts "##{key.to_s} #{default}"
        puts ""
      end
    end
    
    # extract only those parameters in a hash that are from the given class
    #
    # @param [Hash] full_config is the config from which to extract the intersecting options
    #  and it can be an instance of Jeckyl::Config or a hash 
    # @return [Hash] containing all of the intersecting parameters
    #
    # @note this returns a plain hash and not an instance of Jeckyl::Config
    #
    def self.intersection(full_config)
      me = self.new # create the defaults for this class
      my_hash = {}
      me._order.each do |my_key|
        if full_config.has_key?(my_key) then
          my_hash[my_key] = full_config[my_key]
        end
      end
      return my_hash
    end
    
    # return a list of descendant classes in the current context. This is provided to help
    # find classes for the jeckyl utility, e.g. to generate a default config file
    #
    # @return [Array] classes that are descendants of this class, sorted with the least ancestral
    #  first
    #
    def self.descendants
      descs = Array.new
      ObjectSpace.each_object {|obj| descs << obj if obj.kind_of?(Class) && obj < self}
      descs.sort! {|a,b| a < b ? -1 : 1}
      return descs
    end
    
    # get a config file option from the given command line args
    #
    # This is needed with the optparse methods for obvious reasons - the options
    # can only be parsed once and you may want to parse them with a config file specified
    # on the command line. This does it the old-fashioned way and strips the option
    # from the command line arguments.
    #
    # Note that the optparse method also includes this option but just for the benefit of --help
    #
    # @param [Array] args which should usually be set to ARGV
    # @param [String] c_file being the path to the config file, which will be
    #   updated with the command line option if specified.
    #
    def self.get_config_opt(args, c_file)
      #c_file = nil
      if arg_index = args.index('-c') then
        # got a -c option so expect a file next
        c_file = args[arg_index + 1]
        
        # check the file exists
        if c_file && FileTest.readable?(c_file) then
          # it does so strip the args out
          args.slice!(arg_index, 2)

        end
      end
      return [args, c_file]
    end
    
    
    # set the prefix to the parameter names that should be used for corresponding
    # parameter methods defined for a subclass. Parameter names in config files 
    # are mapped onto parameter method by prefixing the methods with the results of
    # this function. So, for a parameter named 'greeting', the parameter method used
    # to check the parameter will be, by default, 'configure_greeting'.
    #
    # For example, to define parameter methods prefix with 'set' redefine this
    # method to return 'set'. The greeting parameter method should then be called
    # 'set_greeting'
    #
    def prefix
      'configure'
    end
    
    # Delete those parameters that are in the given hash from this instance of Jeckyl::Config.
    # Useful for tailoring parameter sets to specific uses (e.g. removing logging parameters)
    #
    # @param [Hash] conf_to_remove which is a hash or an instance of Jeckyl::Config
    #
    def complement(conf_to_remove)
      self.delete_if {|key, value| conf_to_remove.has_key?(key)}
    end
    
    # Read, check and merge another parameter file into this one, being of the same config class.
    #
    # @param [String] conf_file - path to file to parse
    #
    def merge(conf_file)
      
      if conf_file.kind_of?(Hash) then
        self.merge!(conf_file)
      else
        self[:config_files] << conf_file
        
        # get the values from the config file itself
        self.instance_eval(File.read(conf_file), conf_file)
      end
    rescue SyntaxError => err
      raise ConfigSyntaxError, err.message
    rescue Errno::ENOENT
      # duff file path so tell the caller
      raise ConfigFileMissing, "#{conf_file}"
    end
    
    # parse the given command line using the defined options
    #
    # @param [Array] args which should usually be ARGV
    # @yield self and optparse object to allow incidental options to be added
    # @return false if --help so that the caller can decide what to do (e.g. exit)
    def optparse(args)
      
      # ensure calls to parameter methods do not trample on things
      @_last_symbol = nil
      
      opts = OptionParser.new
      # get the prefix for parameter methods (once)
      prefix = self.prefix
      
      opts.on('-c', '--config-file [FILENAME]', String, 'specify an alternative config file')
      
      # need to define usage etc
      
      # loop through each of the options saved
      @_options.each_pair do |param, options|
        
        options << @_descriptions[param] if @_descriptions.has_key?(param)
        
        # opt_str = ''
        # options.each do |os|
        #   opt_str << os.inspect
        # end
        
        # puts "#{param}: #{opt_str}"
        
        # get the method itself to call with the given arg
        pref_method = self.method("#{prefix}_#{param}".to_sym)
        
        # now process the option
        opts.on(*options) do |val|
          # and save the results having passed it through the parameter method
          self[param] = pref_method.call(val)
          
        end
      end
      
      # allow non-jeckyl options to be added (without the checks!)
      if block_given? then
        # pass out self to allow parameters to be saved and the opts object
        yield(self, opts)
      end
      
      # add in a little bit of help
      opts.on_tail('-h', '--help', 'you are looking at it') do
        puts opts
        return false
      end
      
      opts.parse!(args)
      
      return true

    end
    
    # output the hash as a formatted set
    def to_s(opts={})
      keys = self.keys.collect {|k| k.to_s}
      cols = 0
      keys.each {|k| cols = k.length if k.length > cols}
      keys.sort.each do |key_s|
        print '  '
        print key_s.ljust(cols)
        key = key_s.to_sym
        desc = @_descriptions[key]
        value = self[key].inspect
        print ": #{value}"
        print " (#{desc})" unless desc.nil?
        puts
      end
    end
    
    
    protected
    
    # create a description for the current parameter, to be used when generating a config template
    #
    # @param [*String] being one or more string arguments that are used to generate config file templates
    #  and documents
    def comment(*strings)
      @_comments[@_last_symbol] = strings unless @_last_symbol.nil?
    end
    
    # set default value(s) for the current parameter.
    #
    # @param [Object] val - any valid object as expected by the parameter method
    def default(val)
      return if @_last_symbol.nil? || @_defaults.has_key?(@_last_symbol)
      @_defaults[@_last_symbol] = val
    end
    
    # set optparse options for the parameter
    #
    # @param [Array] options using the same format as optparse
    def option(*opts)
      @_options[@_last_symbol] = opts unless @_last_symbol.nil?
    end
    
    # set optparse description for the parameter
    #
    # @param [Array] options using the same format as optparse
    def describe(str)
      @_descriptions[@_last_symbol] = str unless @_last_symbol.nil?
    end
    
    # add in all the parameter checking helper methods
    include Jeckyl::Helpers
    
    private
    
    # decides what to do with parameters that have not been defined.
    # unless @_relax then it will raise an exception. Otherwise it will create a key value pair
    #
    # This method also remembers the method name as the key to prevent the parsers etc from
    # having to carry this around just to do things like report on it.
    #
    def method_missing(symb, parameter)
    
      @_last_symbol = symb
      #@parameter = parameter
      method_to_call = ("#{self.prefix}_" + symb.to_s).to_sym
      set_method = self.method(method_to_call)
    
      self[@_last_symbol] = set_method.call(parameter)
    
    rescue NameError
      #raise if @@debug
      # no parser method defined.
      unless @_relax then
        # not tolerable
        raise UnknownParameter, format_error(symb, parameter, "Unknown parameter")
      else
        # feeling relaxed, so lets store it anyway.
        self[symb] = parameter
      end
    
    end
    
    # get_defaults
    #
    # calls each method with the specified prefix with no parameters so that the defaults
    # defined for each will be passed back and used to set the hash before the
    # config file is evaluated.
    #
    def get_defaults(opts={})
      flag_errors = opts[:flag_errors] 
      local = opts[:local]
    
      # go through all of the methods
      self.class.instance_methods(!local).each do |method_name|
        if md = /^#{self.prefix}_/.match(method_name) then
    
          # its a prefixed method so get it
    
          pref_method = self.method(method_name.to_sym)
          # get the corresponding symbol for the hash
          @_last_symbol = md.post_match.to_sym
          @_order << @_last_symbol
          # and call the method with any parameter, which will
          # call the default method where defined and capture its value
          # Note that a default is defined in the same terms as the input
          # to its parameter method, and may therefore need to be processed
          # by the method to get the desired value. For example, if a parameter
          # method expects data expressed in MBytes, but passes on bytes then
          # the method has to be called with the default to get the real or final
          # default. This is done in the block after this one:
          begin
            a_value = pref_method.call(1)
          rescue Exception
            # ignore any errors, which are bound to result from passing in 1
          end
          begin
            # now set the actual default by calling the method again and passing
            # the captured default, providing a result which may be different if the method transforms
            # the parameter!
            param = @_defaults[@_last_symbol]
            self[@_last_symbol] = pref_method.call(param) unless param.nil?
          rescue Exception
            raise if flag_errors
            # ignore any errors raised
          end
        end
      end
    end
    
    # really private helpers that should not be needed unless the parser method
    # is custom
    
    protected
    
    # helper method to format exception messages. A config error should be raised
    # when the given parameter does not match the checks.
    #
    # The exception is raised in the caller's context to ensure backtraces are accurate.
    #
    # @param [Object] value - the object that caused the error
    # @param [String] message to include in the exception
    #
    def raise_config_error(value, message)
      raise ConfigError, format_error(@_last_symbol, value, message), caller
    end
    
    # helper method to format exception messages. A syntax error should be raised
    # when the check method has been used incorrectly. See check methods for examples.
    #
    # The exception is raised in the caller's context to ensure backtraces are accurate.
    #
    # @param [String] message to include in the exception
    #
    def raise_syntax_error(message)
      raise ConfigSyntaxError, message, caller
    end
    
    # helper method to format an error
    def format_error(key, value, message)
      "[#{key}]: #{value} - #{message}"
    end

  end
  
  # define an alias for backwards compatitbility
  # @deprecated Please use Jeckyl::Config
  Options = Config

end

