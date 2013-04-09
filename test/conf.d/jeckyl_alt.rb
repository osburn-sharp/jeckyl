#
# Jeckyl test file
#

root = File.expand_path('../..', File.dirname(__FILE__))

# should be a writable directory
log_dir File.join(root, "test")

#should be a valid symbol
log_level :debug

# should be an integer
log_rotation 10

# can be a float or any numeric
threshold 2.3
threshold 9.6

# must be a float
pi 3.1459276

# array of anything
collection ["names", 1, true ]
# array of integers
sieve [2, 5, 7, 10, 15]

# hash of anything
my_opts = {:peter=>37, :paul=>40, :birds=>true}
option_set my_opts

# string formatted as email address
email "robert@osburn-sharp.ath.cx"

# real booleans
debug false
debug true

# generous booleans
flag "true"
flag "false"
flag "off"
flag "on"
flag "yes"
flag "no"
flag 1
flag 0


# new things
offset 134

start_day 6

log_level :debug
