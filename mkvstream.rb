# Streams from an MKV file

require 'yaml'

class MKVStream
    def initialize params
        @properties = params
        raise "No track number found" if @properties[ :number ].nil?
        raise "No type found" if @properties[ :type ].nil?
    end

    def extract_to dirPath
        # Check if required command is available
        raise "Command not found - mkvextract" unless system( "which mkvextract &> /dev/null" )

        outputStreamFileName = dirPath
        outputStreamFileName += "/" + @properties[ :number ]
        outputStreamFileName += "-" + @properties[ :type ]
        outputStreamFileName += "-" + @properties[ :language ] unless @properties[ :type ] == "video"

        # Extract track
        IO.popen( "mkvextract tracks #{@properties[ :parentFile]} #{@properties[ :number ]}:#{outputStreamFileName}" ) do | process |
            output = process.readlines
        end

        # Output other properties
        File.open( outputStreamFileName + ".yaml", "w" ) do | infoFile |
            infoFile.puts @properties.to_yaml
        end
    end
end

