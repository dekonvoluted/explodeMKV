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

require_relative 'mkvstream'

class MKVFile
    attr_reader :streams

    def initialize filePath
        # Given file must be present
        raise "File not found - #{filePath}" unless File.exist? filePath

        # Extract info about the MKV file
        IO.popen( "mkvinfo #{filePath}" ) do | process |
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
            return if selectedLines.empty?

            # Ensure only one line is found
            raise "Too many values for #{key} found." unless selectedLines.size == 1

            return selectedLines.at( 0 ).sub( /#{key} /, "" ).strip
        end

        allBlocks.each do | block |
            parentFile = filePath
            number = ( getValue.call( block, "Track number:" ).split.at( 0 ).to_i - 1 ).to_s
            name = getValue.call( block, "Name:" )
            type = getValue.call( block, "Track type:" )
            codec = getValue.call( block, "Codec ID:" )
            language = getValue.call( block, "Language:" )
            @streams += [ MKVStream.new( parentFile: filePath, number: number, name: name, type: type, codec: codec, language: language ) ]
        end
    end
end

