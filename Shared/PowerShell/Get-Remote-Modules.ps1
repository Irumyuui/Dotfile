$outputFile = "Remote-Modules.ps1" 

Get-InstalledModule
| Select-Object Name -Unique
| Sort-Object
| ForEach-Object { "Install-Module -Name $($_.Name)" }
| Out-File -FilePath $outputFile -Force -Encoding utf8

Get-Item -Path Remote-Modules.ps1
| ForEach-Object { "Output file saved to $_.FullName" }
| Write-Host
