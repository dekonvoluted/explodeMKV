#!/usr/bin/env ruby

# This file is part of explodeMKV, a ruby script to extract all streams from an MKV file.
# Copyright (c) 2015 Karthik Periagaram <dekonvoluted@gmail.com>

# ExplodeMKV is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ExplodeMKV is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ExplodeMKV.  If not, see <http://www.gnu.org/licenses/>.

require 'optparse'

require_relative 'mkvfile'

options = { output: File.realpath( Dir.pwd ) }

if __FILE__ == $0
    #Force -h if no arguments are provided
    ARGV << "-h" if ARGV.empty?

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

        # Find and extract all streams
        MKVFile.new( input ).explode_to dirName
    end
end

