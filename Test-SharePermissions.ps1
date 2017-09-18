Function Test-SharePermissions {
	<#
	.Synopsis 
		Tests the current user's ability to read, write, and delete a file in a given share.
	
	.Description 
		Tests the current user's ability to read, write, and delete a file in a given share. Supports piping in share paths.
	
	.Parameter SharePath  
		A complete share path (e.g. \\Hostname\ShareName\).
	
	.Example 
		Test-SharePermissions "\\servername\share\"
		Import-Csv c:\temp\shares.csv | ForEach-Object {"\\{0}\{1}\" -f $_.ComputerName, $_.Name} | Test-SharePermissions
	
	.Notes 
	 Updated: 2017-09-18
	 LEGAL: Copyright (C) 2017  Anthony Phipps
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

	[CmdletBinding()]
	PARAM(
		[Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
		$SharePath
	);

	BEGIN{
		$datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Verbose "Started at $datetime";

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        class Share {
			[String] $SharePath
			[DateTime] $DateScanned
			[String] $UserTested
			[String] $FileTested
            [String] $Read
			[String] $Write
			[String] $Delete

		};
		
		$RandomString = -join ((65..90) + (97..122) | Get-Random -Count 10 | Foreach-Object {[char]$_});
	};

	PROCESS{

		$output = $null;
		$output = [Share]::new();

		$output.SharePath = $SharePath;
		$output.UserTested = whoami;
		$output.FileTested = "$RandomString.txt";
		$output.DateScanned = Get-Date -Format u;
		$output.Read = $False;
		$output.Write = $False;
		$output.Delete = $False;
		
		Write-Verbose "Testing Read Permission";

		if (Get-ChildItem $SharePath -Name -ErrorAction SilentlyContinue) {

			$output.Read = $True;
		};
		
		Write-Verbose "Testing Write Permission";
		if (($output.Read) -eq $True) {
			
			New-Item -Path $SharePath -Name "$RandomString.txt" -ItemType "file" -Force -ErrorAction SilentlyContinue | Out-Null;
			
			if (Test-Path $SharePath\$RandomString.txt -PathType Leaf -ErrorAction SilentlyContinue) {
                
                $output.Write = $True;
			};
		};

		Write-Verbose "Testing Delete Permission";
		if (($output.Write) -eq $True) {

			Remove-Item -path $SharePath\$RandomString.txt -ErrorAction SilentlyContinue | Out-Null;

			if (-NOT (Test-Path $SharePath\$RandomString.txt -ErrorAction SilentlyContinue)) {
                
                $output.Delete = $True;
			};
		};

		$elapsed = $stopwatch.Elapsed;
        $total = $total + 1;
        
        Write-Verbose "System $total `t $ThisComputer `t Total Time Elapsed: $elapsed";

		return $output;
	};
	
	END{
        
        $elapsed = $stopwatch.Elapsed;

		Write-Verbose "Total Systems: $total `t Total time elapsed: $elapsed";
	};
};
