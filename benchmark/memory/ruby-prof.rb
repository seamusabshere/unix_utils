require 'rubygems'
require 'bundler/setup'

require 'ruby-prof'

RubyProf.measure_mode = RubyProf::MEMORY

# Profile the code
RubyProf.start

require 'unix_utils'
UnixUtils.shasum("/Users/seamusabshere/Documents/TomTom/HOME/Download/complete/map/USA__Canada___Mexico/USA_Canada_and_Mexico_P.zip", 256)

result = RubyProf.stop

# Print a flat profile to text
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
