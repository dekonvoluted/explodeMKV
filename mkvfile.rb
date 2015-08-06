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
            number = getValue.call( block, "Track number:" ).split.at( 0 )
            name = getValue.call( block, "Name:" )
            type = getValue.call( block, "Track type:" )
            codec = getValue.call( block, "Codec ID:" )
            language = getValue.call( block, "Language:" )
            @streams += [ MKVStream.new( parentFile: filePath, number: number, name: name, type: type, codec: codec, language: language ) ]
        end
    end
end

