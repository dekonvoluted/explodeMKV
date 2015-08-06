#!/usr/bin/env ruby

# Explode an MKV file into constituent streams

require 'optparse'

require_relative 'mkvfile'

options = { output: File.realpath( Dir.pwd ) }

if __FILE__ == $0
    # Parse options
    OptionParser.new do | opts |
        opts.banner = "Usage: #{$0} [OPTIONS] [INPUTS]"

        opts.separator ""
        opts.separator "This tool explodes one or more MKV files into their constituent streams of data. The stream files are placed in a directory named after the original file."

        opts.separator ""
        opts.separator "Options:"

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

        opts.separator ""
        opts.separator "Example:"
        opts.separator "    #{$0} -o /path/to/dir file.mkv"
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

        MKVFile.new( input ).streams.each do | stream |
            stream.extract_to dirName
        end
    end
end

