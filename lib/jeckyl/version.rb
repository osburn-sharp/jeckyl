# Created by Jevoom
#
# 25-Oct-2012
#   Deprecate ConfigRoot constant in favour of Jeckyl.config_dir, which will pick up
#   the environment variable JECKYL_CONFIG_DIR if set or use '/etc/jeckyl'. This is a
#   change from the old, quirky default of '/etc/jermine'.

module Jeckyl
  # version set to 0.2.4
  Version = '0.2.4'
  # date set to 25-Oct-2012
  Version_Date = '25-Oct-2012'
  #ident string set to: jeckyl-0.2.4 25-Oct-2012
  Ident = 'jeckyl-0.2.4 25-Oct-2012'
end
