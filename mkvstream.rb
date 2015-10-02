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
        IO.popen( "mkvextract tracks #{@properties[ :parentFile ]} #{@properties[ :number ]}:#{outputStreamFileName}" ) do | process |
            output = process.readlines
        end

        # Output other properties
        File.open( outputStreamFileName + ".yaml", "w" ) do | infoFile |
            infoFile.puts @properties.to_yaml
        end
    end
end

