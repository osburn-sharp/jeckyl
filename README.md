#JECKYL 

(a.k.a. Jumpin' Ermin's Configurator for Kwick and easY Linux services)

Jeckyl can be used to create a parameters hash from a simple config file written in Ruby, having run whatever checks you want
on the file to ensure the values passed in are valid. All you need to do is define a class inheriting from Jeckyl, methods for
each parameter, its default, whatever checking rules are appropriate and even a comment for generating templates etc.
This is then used to parse a Ruby config file and create the parameters hash. Jeckyl 
comes complete with a utility to check a config file against a given class and to generate a default file for you to tailor.

Jeckyl was inspired by the configuration file methods in [Unicorn](http://unicorn.bogomips.org/).

## Installation

Jeckyl comes as a gem. It can be installed in the usual way:

    gem install jeckyl
    
That is all you need to do. Type 'jeckyl' to see usage and references to documentation.

Jeckyl can be used to set the default location for the config files it processes. This will
be '/etc/jeckyl' unless you set the environment varibale 'JECKYL_CONFIG_DIR' to something else.
This could be done on a system-wide basis by include a file with this variable in /etc/env.d.
    
## Getting Started

To use Jeckyl, create a new parameter class and add a parameter method for each parameter you want to define in
your config files. Think of the name of a parameter and prefix this with `configure_`:

    require 'jeckyl'
    
    class MyConfig < Jeckyl::Config
    
      def configure_my_greeting(greet)
        default "Hello"
        comment "Set the standard greeting for this application"
        
        a_string(greet)
      end
    end
    
The parameter method first sets a default value to be used if no value is given at all in the config file. This is
optional. It then describes the parameter, which is used by `jeckyl` when generating a blank config or a markdown file. Finally
it runs a check on the given parameter to ensure it is a string. Note the name of the method that you use in the
config file itself would be just 'my_greeting' wheras the parameter method is 'configure_my_greeting'.

Jeckyl comes complete with a whole range of checking methods that can be used for defining parameters 
(see {Jeckyl::Config} for details). These methods are handy because they handle errors transparently. 
It is not necessary, however, to use them so long as the value returned by the parameter method is what 
you want in your config hash.

To use this simple example, you can generate a config file with jeckyl:

    $ jeckyl generate config lib/my_app/my_config.rb >test/conf.d/test.rb
    
This will produce something like:

    # Set the standard greeting for this application
    #my_greeting "Hello"
    
Which you could change to:

    # Set the standard greeting for this application
    my_greeting "Welcome"

And then, to use this config file to create the options hash:

    require 'my_app/my_config'
    
    options = MyConfig.new('test/conf.d/test.rb')
    
    options.inspect => {:config_files=>['test/conf.d/test.rb'], :my_greeting=>'Welcome'}
    
## Using Jeckyl

### Example Parameter Methods

Some examples of different parameters are given here, taken from the Jellog::Config class, [Jellog](https://github.com/osburn-sharp/jellog)
being a jazzed-up ruby logger:

    def configure_log_level(lvl)
      default :system
      comment "Controls the amount of logging done by Jellog",
        "",
        " * :system - standard message, plus log to syslog",
        " * :verbose - more generous logging to help resolve problems",
        " * :debug - usually used only for resolving problems during development",
        ""

      lvl_set = [:system, :verbose, :debug]
      a_member_of(lvl, lvl_set)

    end

This shows a multi-line comment, the comment method takes any number of arguments and outputs 
them one per line. It also shows how to test that a key value is used that belongs to a set.


    def configure_log_rotation(int)
      default 2
      comment "Number of log files to retain at any time, between 0 and 20"

      a_type_of(int, Integer) && in_range(int, 0, 20)

    end

This shows how multiple tests can be and'd together.

    def configure_log_length(int)
      default 1 #Mbyte
      comment "Size of a log file (in MB) before switching to the next log, upto 20 MB"

      a_type_of(int, Integer) && in_range(int, 1, 20)
      int * 1024 * 1024
    end 

This shows how the return value can be computed from the input parameter if required.

This final example shows a complicated parameter method that accepts an options hash and can
be called multiple times:

    def configure_sensors(options)
      comment "Add a sensor to monitor etc. This can be called multiple times",
        " ",
        " Sensors must be defined with the following:",
        "   :device - name of a device previously added with add_device",
        "   :name - the name for this thermostat (e.g. name of the room being monitored)",
        " ",
        " Sensors can have the following options:",
        "   :slope - gradient of the residual error function for the given sensor, default 0.0",
        "   :intercept - from the residual error function, default 0.0",
        " "

      unless @sensors
        @sensors = Array.new
      end

      # remember the sensor names
      unless @names
        @names = Array.new
      end

      unless options.has_key?(:device)
        raise Jeckyl::ConfigError, "You must supply a :device for each sensor"
      end
      unless @devices.include?(options[:device])
        raise Jeckyl::ConfigError, "You must name a device that has already been added"
      end
      unless options.has_key?(:name)
        raise Jeckyl::ConfigError, "You must supply a :name for each sensor"
      end
      @sensors.each do |sensor|
        raise Jeckyl::ConfirError, "Each name must be unique" if sensor[:name] == options[:name]
      end
      a_type_of(options[:name], String)

      raise Jeckyl::ConfigError, "You must supply an index" unless options.has_key?(:index)
      a_type_of(options[:index], Integer) && in_range(options[:index], 1, 4)

      options[:slope] ||= 0.0
      a_type_of(options[:slope], Float)

      options[:intercept] ||= 0.0
      a_type_of(options[:intercept], Float)

      @names << options[:name]

      @sensors << options # return the current array of sensors

    end

The method uses its own instance variables to keep track of things over multiple calls and
returns the @sensors array so that the actual parameter returned from Jeckyl will be the last value
returned. It uses a mixture of jeckyl tests and explicit tests to ensure the parameters are correct.
If preferred, you can add custom helper methods to your parameter class in the same manner as {Jeckyl::Config}.

### Writing Ruby

Because the config file is ruby, it can contain any valid ruby code to help construct your parameters,
which can be instances of complex classes if required. BUT this also means the code can do things you
might not have intended so some care is needed here!

One of the things you can add, if it helps, is your own checking method. Call it what you like, pass in the object
to check (and whatever else you need) and either return the item or raise an error if the checks fail. There
are two methods available: {Jeckyl::Config#raise_config_error} e.g. for defining a value
outside the required range and {Jeckyl::Config#raise_syntax_error} e.g. for defining a string where a number is required.

### Can't be bothered? a more relaxed approach

If you are lazy and cannot be bothered with defining lots of methods, you can relax the parsing and checking and convert a
parameter file straight into an options hash. To relax checking, set the :relax option to true when creating the parameters hash. 
Then any parameter value pairs in the config file will be converted to key-value pairs in the hash 
without any checks at all. You obviously cannot do much with this approach but in simple cases it may be OK? 

If you don't like having to prefix your parameter methods with 'configure_' you can set another prefix
by redefining the prefix method in your subclass to return something else:

    def prefix
      'set' # could also be 'cf' if you find typing a bore
    end

### Managing Parameter Hashes

You can easily merge parameter files using the {Jeckyl::Config#merge} method:

    config = MyConfig.new('/etc/system.rb')
    config.merge(File.join(ENV[USER], '.my_config_.rb'))
    config.merge('./.local_config_.rb')

Jeckyl includes a couple of methods to help sub-divide parameter hashes. To extract 
all of the parameters from a hash that belong to a given Jeckyl class, use Class.intersection(hash) (see 
{Jeckyl::Config.intersection}). And to remove all of the parameters from one config hash in another, 
use conf.complement(hash) ({Jeckyl::Config#complement}).

For example, the Jellog logger defines a set of logging parameters in Jellog::Config. These may be inherited
by another service that adds its own parameters (such as Jerbil):

    options = Jerbil::Config.new(my_conf)
    
    log_opts = Jellog::Config.intersection(options)
    
    jerb_opts = options.complement(log_opts)
    
### Some Internal Methods


### Jeckyl::Config < Hash

Finally, note that Jeckyl::Config is itself a subclass of Hash, and therefore Jeckyl config objects inherit
all hash methods as well!

## The 'jeckyl' Command

Jeckyl comes with a simple script: bin/jeckyl to help in creating, checking and documenting parameters.

You can create a simple config class to start you off with:

    $ jeckyl klass <name>
      
which will output a small template to stdout. By default this will inherit from {Jeckyl::Config} but
you can add another parent with, for example:

    $ jeckyl klass MyService JerbilService::Config
    
Save the file and edit it to add your parameters as required. Once you have defined the config class, 
you can generate a default config file for your application using:

    $ jeckyl config path/to/config_class.rb

This will generate a config file on stdout for each of the parameters, with the comment defined in the
parameter method and the default value where defined. Defaults will be commented out. You can save this file and edit it
to create a new config file.

Where you have created a config class that inherits from another config class, you will probably want to create
a config file with all of the parameters in it. By default only the config class defined in the given file
will be generated. To generate all parameters add the -k (for concat) option:

    $ jeckyl config path/to/config_class.rb -k
    
The resulting config file will be neatly divided into sections, one for each class, starting with the most
ancestral. If you want to know what config classes you have inherited, then try:

    $ jeckyl list path/to/config_class.rb
    
This will output an indexed list of the classes available. If you wanted to generate a config file just for one class, 
select it with the -C option and the index from the list:

    $ jeckyl config path/to/config_class.rb -C 2
    
Once you have editted your config file you can check if it is OK:

    $ jeckyl check path/to/config_class.rb path/to/config_file.rb
    
This will either display error messages or tell you that the config file is OK.

Having created a config class, you may want to document it. Given that each parameter is already described within
the parameter method, it would be inconvenient to have to copy these comments into ruby comments just to
help the various documentation tools around. Instead, you can generate a markdown file from the parameter methods
and then include this in your documentation:

    $ jeckyl markdown path/to/config_class.rb
    
This task takes the same options as the config task. You can then include a reference or link to this file
in the header comment for your config class. The template generated above already has a yard @see directive.

    # @see file:lib/project/config_comments.md

    
## Code Walkthrough

Jeckyl is documented on [RubyDoc.info](http://rdoc.info/github/osburn-sharp/jeckyl/frames).

Jeckyl consists of a single class: {Jeckyl::Config}. When you create an instance of a subclass the following
happens (see {Jeckyl::Config#initialize}):

+ all of the parameter methods are called by {Jeckyl::Config#get_defaults} to obtain their default values 
  (the {Jeckyl::Config#default default} method sets this in a hash)
  and are called again with these default values to process them through whatever the parameter method defines. This
  ensures, for example, that if the parameter is multiplied by 10 before being added to the config hash, 
  the default value is also multipled by 10.
  
+ if no config file is provided, the default values are returned as the options hash. This is used, for example,
  by the config {Jeckyl::Config.generate_config generator}.
  
+ finally, the given config file (whose name is added to the hash) is evaluated so that the resulting parameters are
  added, overriding any defaults or manually entered values.
  
All of this is done with just a little bit of meta-magic. When the config file is eval'ed the parameter names are eval'ed
in the context of the instance being created, but because the parameter methods are all prefixed with something (configure by default)
method_missing is called instead. This orchestrates the setting of parameters and collecting of results into the options
hash, passing the parameter values to the corresponding parameter method. 

For example, a config file might contain:

    # define a greeting for the application
    greeting "Hello"
    
There is no greeting method, so method_missing is called instead. This remembers the name of the "missing" method (:greeting),
calls configure_greeting and stores the results in the instances hash. The main reason for doing this (as opposed to just
calling the method 'greeting') is to enable the evaluation of defaults and comments in the context of each parameter method. 
All of this is private and therefore under the bonnet.

## Dependencies

See the {file:Gemfile} for details of dependencies.

Tested on Ruby 1.8.7.

## Testing Jeckyl

There is an rspec test file to test the whole thing (spec/jeckyl_spec.rb). It uses the test subclass in "../test" and 
various config files in "../conf.d". There is another rspec file that tests the config_check function.
  

## Why did I bother?

Having tried various config file solutions, I had ended up using yaml files, but i found
checking them very difficult because they are not very friendly and very sensitive to spacing
issues. In looking for yet another alternative, I came across the approach used by
Unicorn (the backend web machine I now use for Rails apps). I liked the concept but
thought it could be made more general, which resulted in Jeckyl.

## Bugs etc

Details of bugs can be found in {file:Bugs.rdoc}

## Author and Contact

I am Robert Sharp and you can contact me on [GitHub](http://github.com/osburn-sharp)

## Copyright and Licence

Copyright (c) 2011-2012 Robert Sharp. 

See {file:LICENCE.rdoc LICENCE} for details of the licence under which Jeckyl is released.

## Warranty

This software is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.
