function Hunt-RecycleBin {
    <#
    .Synopsis 
        Gets the login sessions for the given computer(s).

    .Description 
        Gets the login sessions for the given computer(s) utizling the builtin "qwinsta.exe" tool.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-RecycleBin 
        Hunt-RecycleBin SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-RecycleBin
        Hunt-RecycleBin -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-RecycleBin

    .Notes 
        Updated: 2017-10-17

        Contributing Authors:
            Anthony Phipps
            
        LEGAL: Copyright (C) 2017
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.
    #>

    param(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        
        [Parameter()]
        $Fails
    );

	begin{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose ("Started at {0}" -f $datetime);

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;

        class DeletedItem {
            [string] $Computer
            [Datetime] $DateScanned  

            [String] $LinkType
            [String] $Name
            [String] $Length
            [String] $Directory
            [String] $IsReadOnly
            [String] $Exists
            [String] $FullName
            [String] $CreationTimeUtc
            [String] $LastAccessTimeUtc
            [String] $LastWriteTimeUtc
            [String] $IsContainer
            [String] $Mode
        };
    };

    process{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        
        Write-Verbose ("{0}: Querying remote system" -f $Computer); 
        $recycleBin = $null;
        $recycleBin = Invoke-Command -ComputerName $Computer -ErrorAction SilentlyContinue -ScriptBlock {
            Get-ChildItem ("{0}\`$Recycle.Bin" -f $env:SystemDrive) -Force -Recurse;
         };
       
        if ($recycleBin) { 
            
            $OutputArray = @();

            Write-Verbose ("{0}: Looping through retrived results" -f $Computer);
            foreach ($recycled in $recycleBin) {
             
                $output = $null;
                $output = [DeletedItem]::new();
                
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

                $output.LinkType = $recycled.LinkType
                $output.Name = $recycled.Name
                $output.Length = $recycled.Length
                $output.Directory = $recycled.Directory
                $output.IsReadOnly = $recycled.IsReadOnly
                $output.Exists = $recycled.Exists
                $output.FullName = $recycled.FullName
                $output.CreationTimeUtc = $recycled.CreationTimeUtc
                $output.LastAccessTimeUtc = $recycled.LastAccessTimeUtc
                $output.LastWriteTimeUtc = $recycled.LastWriteTimeUtc
                $output.IsContainer = $recycled.PSIsContainer
                $output.Mode = $recycled.Mode

                $OutputArray += $output;
            };

            $elapsed = $stopwatch.Elapsed;
            $total = $total + 1;
            
            Write-Verbose ("System {0} complete: `t {1} `t Total Time Elapsed: {2}" -f $total, $Computer, $elapsed);

            $total = $total+1;
            return $OutputArray;
        }
        else {
            
            Write-Verbose ("{0}: System unreachable." -f $Computer);
            if ($Fails) {
                
                $total = $total+1;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [DeletedItem]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $total = $total+1;
                return $output;
            };
        };
    };

    end {

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};