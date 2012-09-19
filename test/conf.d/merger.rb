#
# Jeckyl test file
#

# should be a writable directory
log_dir "./test/reports"

#should be a valid symbol
log_level :debug

# should be an integer
log_rotation 6

# can be a float or any numeric
threshold 5.6
threshold 10

# must be a float
pi 3.14592

# array of anything
collection ["names", 1, true ]
# array of integers
sieve [2, 5, 7, 10, 15]

# hash of anything
my_opts = {:peter=>37, :paul=>40, :birds=>true}
options my_opts

# string formatted as email address
email "robert@osburn-associates.ath.cx"