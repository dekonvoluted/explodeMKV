#!/usr/bin/env ruby

# Explode an MKV file into constituent streams

require 'optparse'

options = { output: File.realpath( Dir.pwd ) }

if __FILE__ == $0
    # Parse options
    OptionParser.new do | opts |
        opts.banner = "Usage: #{$0} [OPTIONS] [INPUTS]"

        opts.on( "-o", "--output PATH", "Write output to PATH" ) do | outputPath |
            begin
                options[ :output ] = File.realpath outputPath
            rescue => error
                puts error.message
            end
        end

        opts.on( "-h", "--help", "Display this message" ) do
            puts opts
        end
    end.parse!

    # Ensure output directory is writable
    begin
        raise "Output path is not writable - #{options[ :output ] }" unless File.writable? options[ :output ]
    rescue => error
        puts error.message
    end

    # Process inputs
    ARGV.each do | input |
        dirName = options[ :output ]
        dirName += "/" + Time.new.strftime( "#{File.basename( input, ".mkv" )}-%Y%m%dT%H%M" )
        if Dir.exist? dirName
            count = 1
            count += 1 while Dir.exist? dirName + "-" + count.to_s
            dirName += "-" + count.to_s
        end
        Dir.mkdir dirName
    end
end

