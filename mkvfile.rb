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

require 'yaml'

class MKVFile
    attr_reader :streams

    def initialize filePath
        # Given file must be present
        raise "File not found - #{filePath}" unless File.exist? filePath
        @filePath = filePath

        # Extract info about the MKV file
        IO.popen( "mkvinfo #{@filePath}" ) do | process |
            @fileInfo = process.readlines
        end

        # Parse the information to find streams
        previousIndentationLevel = 0
        currentIndentationLevel = 0
        recordLine = false
        allBlocks = Array.new
        currentBlock = Array.new
        @fileInfo.each_with_index do | line, lineno |
            currentIndentationLevel = line.index "+"

            if currentIndentationLevel >= previousIndentationLevel
                if recordLine
                    currentBlock += [ line[ currentIndentationLevel + 2..-1 ] ]
                end
            else
                if recordLine
                    recordLine = false
                    allBlocks += [ currentBlock ] unless currentBlock.empty?
                    currentBlock = Array.new
                end
            end

            if line == "| + A track\n"
                if recordLine
                    allBlocks += [ currentBlock ] unless currentBlock.empty?
                    currentBlock = Array.new
                end
                recordLine = true
            end

            previousIndentationLevel = currentIndentationLevel
        end

        # Record each stream
        @streams = Array.new

        getValue = lambda do | block, key |
            # Find lines containing key
            selectedLines = block.select { | line | line.match /#{key}/ }
            return String.new if selectedLines.empty?

            # Ensure only one line is found
            raise "Too many values for #{key} found." unless selectedLines.size == 1

            return selectedLines.at( 0 ).sub( /#{key} /, "" ).strip
        end

        allBlocks.each do | block |
            number = ( getValue.call( block, "Track number:" ).split.at( 0 ).to_i - 1 ).to_s
            name = getValue.call( block, "Name:" )
            type = getValue.call( block, "Track type:" )
            codec = getValue.call( block, "Codec ID:" )
            language = getValue.call( block, "Language:" )
            @streams += [ { number: number, name: name, type: type, codec: codec, language: language } ]
        end
    end

    def explode_to dirPath
        # Check if required command is available
        raise "Command not found - mkvextract" unless system( "which mkvextract &> /dev/null" )

        trackOptions = Array.new
        timecodeOptions = Array.new

        # Prepare to extract each track
        @streams.each do | params |
            # Name of the output stream file
            outputStreamFileName = dirPath
            outputStreamFileName += "/" + params[ :number ]
            outputStreamFileName += "-" + params[ :type ]
            outputStreamFileName += "-" + params[ :language ] unless params[ :type ] == "video" or params[ :language ].empty?

            # Options to use to extract the output stream
            trackOptions << "#{params[ :number ]}:#{outputStreamFileName}"
            timecodeOptions << "#{params[ :number ]}:#{outputStreamFileName}.txt" if params[ :type ] == "video" or params[ :type ] == "audio"

            # Properties of the output stream
            File.open( outputStreamFileName + ".yaml", "w" ) do | infoFile |
                infoFile.puts params.to_yaml
            end
        end

        # Extract all tracks
        IO.popen( "mkvextract tracks " + @filePath + " " + trackOptions.join( " " ) ) do | process |
            output = process.readlines
        end

        # Extract timecodes
        unless timecodeOptions.empty?
            IO.popen( "mkvextract timecodes_v2 " + @filePath + " " + timecodeOptions.join( " " ) ) do | process |
                output = process.readlines
            end
        end
    end
end

