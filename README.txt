= JECKYL 

== Jumpin' Ermin's Configurator for Kwick and easY Linux services

Create an options hash from a simple config file to be used to configure a ruby service, Safely!
Define permitted options, their defauls, checking rules and even comments in one simple class. This
is then used to parse the config file and create the options hash. And a config-checker and config-file
generator can be easily created by modifying standard templates to suit your config class.

== Usage

Create a subclass of Jeckyl in which to define methods to parse each of your
parameters. For each parameter in the config file there needs to be a method with the
same name but prefixed with "configure_". For example, if there is a parameter "log_dir" then there
needs to be a method called "configure_log_dir". Each method should be called with one parameter value,
which can be assigned a default value. Jeckyl uses these defaults to create default values
in the options hash. When you create an instance of the configurator, you can pass in
a hash with additional options or values to overide these defaults.

Within each method you can use any of the helpers defined in Jeckyl to check that the parameter
given is valid. Each helper will raise appropriate exceptions if the parameter does not
match. If the parameter is OK you can return it as-is or you can modify it. For example,
you could turn a convenient MB size parameter as bytes by multiplying the parameter before
returning it. Some helper methods modify the value for you (e.g. a_flag returns boolean for
any of the valid flag options).

You can also have multiple fields for a parameter, just make sure you pass in multiple parameters
to the method class. But, these fields need to be reduced to a single hash entry. This allows
you, for example, to perform checks on simple fields before combining them into a complex
object, hidden from the config file writer.

You can easily add your own helpers if you need to. Check the ones in Jeckyl to see how they
work.

There is also a helper called "comment" which takes any number of comment strings as parameters.
Jeckyl saves these strings as arrays in a similar hash indexed by the same parameter name.
These comments are output when you generate a config template with the generate_config class method.

The successfully returned config hash contains key-value pairs where the keys are the
parameter names as symbols and the values are the objects passed in. This means that
along with the usual simple parameters such as filenames, numbers etc, you can construct
any valid Ruby object and pass that in as a parameter. Wonderful!

And because Jeckyl is itself a subclass of Hash, the resulting object behaves just
like a normal hash would. Fantastic!

If you are lazy and cannot be bothered with defining lots of methods, you can relax the parsing
and even use Jeckyl as-is. To relax, call the class method, "relax". Then any parameter value pairs in
the config file will be converted to key-value pairs in the hash without any checks at all. Great!

=== Why?

Having tried various config file solutions, I had ended up using yaml files, but i found
checking them very difficult because they are not very friendly and very sensitive to spacing
issues. In looking for yet another alternative, I came across the approach used by
Unicorn (the backend web machine I now use for Rails apps). I liked the concept but
thought it could be made more general, which resulted in Jeckyl.

=== Example

A good example is provided in the test configurator, TestJeckyl in the test directory.

== Testing / adapting

There is an rspec test file to test the whole thing. It uses the test subclass in "../test" and various config files
in "../conf.d". There is another rspec file that tests the config_check function.

There are also two basic scripts in the bin directory:

* jeckyl_check_config config_file - will check the given config file and generates error or success messages
* jeckyl_generate_config - creates a config template from the configurator class.

== Installation

Its DIY at the moment. I dont use gems to manage ruby files I generate on my network because
I haven't figured a fool-proof way to ensure all machines can see the same files all of
the time.

== Contact

robert

== Copyright

Copyright (c) 2011 Robert Sharp. See LICENCE for details. (Yes, with a C!)

== Warranty

This software is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.
