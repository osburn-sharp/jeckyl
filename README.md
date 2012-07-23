#JECKYL 

## Jumpin' Ermin's Configurator for Kwick and easY Linux services

Jeckyl can be used to create an options hash from a simple config file. All you need to do is define 
permitted options, their defaults, checking rules and even comments in one simple class. This
is then used to parse the config file and create the options hash. Jeckyl comes complete with a utility
to check a config file against a given class and to generate a default file for you to tailor.

## Installation

Jeckyl comes as a gem and can be installed in the usual way:

    gem install jeckyl
    
## Getting Started

Jeckyl provides the {Jeckyl::Options} class to which a user has to add their own parameter methods. Think of
the name of a parameter and prefix this with `configure_`:

    require 'jeckyl'
    
    class MyConfig < Jeckyl#Options
    
      def configure_my_greeting(greet)
        default "Hello"
        comment "Set the standard greeting for this application"
        
        a_string(greet)
      end
    end
    
The method first sets a default value to be used if no value is given at all in the config file. This is
optional. It then describes the parameter, which is used by `jeckyl` when generating a blank config. Finally
it runs a check on the given parameter to ensure it is a string.

Jeckyl comes complete with a whole range of checking methods that can be used for defining parameters. These
methods are handy because they handle errors transparently. It is not necessary, however, to use them so long as
the value returned by the parameter method is what you want in your config hash.

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
    
    options.inspect => {:config_file=>'test/conf.d/test.rb', :my_greeting=>'Welcome'}
    
Some examples of different parameters are given here, taken from the Jelly::Options class, Jelly being
a jazzed-up ruby logger:

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

This shows a multi-line comment, the comment method takes any number of arguments and outputs 
them one per line. It also shows how to test that a key value is used that belongs to a set.


    def configure_log_rotation(int)
      default 2
      comment "Number of log files to retain at any time, between 0 and 20"

      a_type_of(int, Integer) && in_range(int, 0, 20)

    end

This shows how multiple tests can be anded together.

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
If preferred, you can add custom helper methods to your options class in the same manner as {Jeckyl::Options}.

Because the config file is ruby, it can contain any valid ruby code to help construct your parameters,
which can be instances of complex classes if required. BUT this also means the code can do things you
might not have intended so some care is needed here!

If you are lazy and cannot be bothered with defining lots of methods, you can relax the parsing
and even use Jeckyl as-is. To relax, call the class method, {Jeckyl::Options.relax}. Then any parameter value pairs in
the config file will be converted to key-value pairs in the hash without any checks at all. You obviously cannot do
much with this approach but in simple cases it may be OK? If, so some strange reason, you want to turn checking back on
then {Jeckyl::Options.strict} will do the trick

If you don't like having to prefix your parameter methods with 'configure_' you can set another prefix
by redefining the prefix method to return something else:

    def prefix
      'set'
    end

Jeckyl now includes a couple of methods to help sub-divide config hashes. To extract 
all of the options from a hash that belong to a given Jeckyl class, use Class.intersection(hash) (see 
{Jeckyl::Options.intersection}). And to remove all of the options from one config hash in another, 
use conf.complement(hash) ({Jeckyl::Options#complement}).

For example, the Jelly logger defines a set of logging parameters in Jelly::Options. These may be inherited
by another service that adds its own parameters (such as Jerbil):

    options = Jerbil::Options.new(my_conf)
    
    log_opts = Jelly::Options.intersection(options)
    
    jerb_opts = options.complement(log_opts)
    
Finally, note that Jeckyl::Options is itself a subclass of Hash, and therefore Jeckyl config objects inherit
all hash methods as well!
    
    
## Code Walkthrough

Jeckyl consists of a single class: {Jeckyl::Options}. When you create an instance of a subclass the following
happens (see {Jeckyl::Options#initialize}):

+ all of the parameter methods are called by {Jeckyl::Options#get_defaults} to obtain their default values 
  (the {Jeckyl::Options#default default} method sets this in a hash)
  and are called again with these default values to process them through whatever the parameter method defines. This
  ensures, for example, that if the default is multiplied by 10, the resulting value is also.
  
+ if no config file is provided, the default values are returned as the options hash. This is used, for example,
  by the config {Jeckyl::Options.generate_config generator}.
  
+ otherwise, the optional options hash that can be passed in to the new method is merged with the defaults, 
  allowing the caller to provide some local overrides to the defaults, or even add parameters that have not 
  been defined anywhere else!
  
+ finally, the given config file (whose name is added to the hash) is evaluated so that the resulting parameters are
  added, overriding any defaults or manually entered values.
  
All of this is done with just a little bit of meta-magic. When the config file is eval'ed the parameter names are eval'ed
in the context of the instance being created, but because the parameter methods are all prefixed with something (configure by default)
method_missing is called instead. This orchestrates the setting of parameters and collecting of results into the options
hash, passing the parameter values to the corresponding parameter method. Simples, really.

## Dependencies

See the {file:Gemfile} for details of dependencies.

Tested on Ruby 1.8.7.

## Testing 

There is an rspec test file to test the whole thing. It uses the test subclass in "../test" and various config files
in "../conf.d". There is another rspec file that tests the config_check function.
  
## Utilities

Jeckyl comes with a simple script: bin/jeckyl. This offers the following:

   $ jeckyl generate config a_class

This will output to stdout a config file based on the jeckyl class a_class. This
can either be a ruby file path or the name of a library that is accessible through
rubygems. Note where a class is itself a subclass of another config class then the
command above will display all of the classes. A specific class can be selected by entering
its name:

    $ jeckyl generate config subclass Sclass

A simple template can be generated as follows:

    $ jeckyl generate klass <name> [parent]

This will create a very simple template for a module <name> and a class Options that 
will be a descendant of parent or Jeckyl::Options if not parent is specified.

There is also a command that generates a markdown file containing all of the comments, so that you can
easily include them in your yard docs. Run the command:

    $ jeckyl comment path/to/config_class [class_name] >lib/project/config_comments.md
    
It seems to be difficult to get this markdown into the yard docs, but one way is to add it
as a @see tag:

    # @see file:lib/project/config_comments.md

Finally:

    $ jeckyl check <class> <conf> [class_name]

will run a check on the <conf> file against the <class> file. As before, if there are more
than one class in the hierarchy, select the right one with [class_name].

## Why did I bother?

Having tried various config file solutions, I had ended up using yaml files, but i found
checking them very difficult because they are not very friendly and very sensitive to spacing
issues. In looking for yet another alternative, I came across the approach used by
Unicorn (the backend web machine I now use for Rails apps). I liked the concept but
thought it could be made more general, which resulted in Jeckyl.

## Bugs etc

One annoying feature is that generated config files do not put the parameters in the same order
as they are defined. This means that related parameters are scattered across the config file. There
is no natural solution to this without parsing the class file as a text file to work out the order.
Need to consider this at some point?

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
