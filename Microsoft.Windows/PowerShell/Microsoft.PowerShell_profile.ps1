# Enable starship
Invoke-Expression (&starship init powershell)

# Import-Module PSReadLine
Import-Module posh-git
Import-Module -Name Terminal-Icons
Import-Module Az.Accounts
Import-Module Az.Tools.Predictor
Import-Module -Name CompletionPredictor

Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function MenuComplete

# Shows navigable menu of all options when hitting Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Autocompleteion for Arrow keys
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -PredictionSource History

Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView

#Set the color for Prediction (auto-suggestion)
Set-PSReadLineOption -Colors @{
  Command            = 'Green'
  Number             = 'DarkBlue'
  Member             = 'DarkBlue'
  Operator           = 'DarkBlue'
  Type               = 'DarkBlue'
  Variable           = 'DarkGreen'
  Parameter          = 'DarkGreen'
  ContinuationPrompt = 'DarkBlue'
  Default            = 'DarkBlue'
  InlinePrediction   = 'DarkGray'
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# Alias
# Set-Alias -Name ls -Value eza
# Set-Alias -Name cat -Value bat
