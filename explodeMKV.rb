#!/usr/bin/env ruby

# Explode an MKV file into constituent streams

require 'optparse'

if __FILE__ == $0
    # Parse options
    OptionParser.new do | opts |
        opts.banner = "Usage: #{$0} [OPTIONS] [INPUTS]"

        opts.on( "-h", "--help", "Display this message" ) do
            puts opts
        end
    end.parse!

    # Process inputs
    ARGV.each do | input |
    end
end

