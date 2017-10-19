FUNCTION Hunt-ScheduledTasks {
    <#
    .Synopsis 
        Gets the scheduled tasks on a given system.

    .Description 
        Gets the scheduled tasks on a given system.

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-ScheduledTasks 
        Hunt-ScheduledTasks SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-ScheduledTasks
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-ScheduledTasks

    .Notes 
        Updated: 2017-10-10

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

    PARAM(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        [Parameter()]
        $Fails

    );

	BEGIN{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();

        $total = 0;

        class Task {
            [String] $Computer
            [DateTime] $DateScanned

            [String] $ActionsArguments
            [String] $ActionsExecute
            [String] $ActionsId
            [String] $ActionsWorkingDirectory
            [String] $Author
            [String] $Description
            [String] $SecurityDescriptor
            [String] $Source
            [String] $State
            [String] $TaskName
            [String] $TaskPath
            [String] $TriggersDelay
            [String] $TriggersEnabled
            [String] $TriggersEndBoundary
            [String] $TriggersExecutionTimeLimit
            [String] $TriggersPSComputerName
            [String] $TriggersRepetition
            [String] $TriggersStartBoundary
            [String] $URI
        }
	}

    PROCESS{

        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present

        $Tasks = $null;
                        
		$Tasks = Invoke-Command -ComputerName $Computer -ScriptBlock {Get-ScheduledTask | Select-Object *} -ErrorAction SilentlyContinue;
            
        if ($Tasks) {

            $Tasks | ForEach-Object {

                $output = $null;
                $output = [Task]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

                $output.ActionsArguments = ($_.Actions.Arguments -join "; ");
                $output.ActionsExecute = ($_.Actions.Execute -join "; ");
                $output.ActionsId = ($_.Actions.Id -join "; ");
                $output.ActionsWorkingDirectory = ($_.Actions.WorkingDirectory -join "; ");
                $output.Author = $_.Author;
                $output.Description = $_.Description;
                $output.SecurityDescriptor = $_.SecurityDescriptor;
                $output.Source = $_.Source;
                $output.State = $_.State;
                $output.TaskName = $_.TaskName;
                $output.TaskPath = $_.TaskPath;
                $output.TriggersDelay = ($_.Triggers.Delay -join "; ");
                $output.TriggersEnabled = ($_.Triggers.Enabled -join "; ");
                $output.TriggersEndBoundary = ($_.Triggers.EndBoundary -join "; ");
                $output.TriggersExecutionTimeLimit = ($_.Triggers.ExecutionTimeLimit -join "; ");
                $output.TriggersPSComputerName = ($_.Triggers.PSComputerName -join "; ");
                $output.TriggersRepetition = ($_.Triggers.Repetition -join "; ");
                $output.TriggersStartBoundary = ($_.Triggers.StartBoundary -join "; ");
                $output.URI = $_.URI;

                return $output;
            };
        }
        else {
            
            Write-Verbose ("{0}: System failed." -f $Computer);
            if ($Fails) {
                
                $total++;
                Add-Content -Path $Fails -Value ("$Computer");
            }
            else {
                
                $output = $null;
                $output = [ArpCache]::new();

                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;
                
                $total++;
                return $output;
            };
        };
    };

    end {

        $elapsed = $stopwatch.Elapsed;

        Write-Verbose ("Total Systems: {0} `t Total time elapsed: {1}" -f $total, $elapsed);
    };
};