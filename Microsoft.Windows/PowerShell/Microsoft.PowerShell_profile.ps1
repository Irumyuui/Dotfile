# Enable UTF-8 encoding for PowerShell console
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

# Enable starship
Invoke-Expression (&starship init powershell)

# Import-Module PSReadLine
Import-Module -Name Terminal-Icons
Import-Module -Name z
Import-Module posh-git

Import-Module Az.Accounts
Import-Module Az.Tools.Predictor
Import-Module -Name CompletionPredictor

Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function MenuComplete

# Autocompleteion for Arrow keys
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Shows navigable menu of all options when hitting Tab
# Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord Tab -Function MenuComplete

Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -ShowToolTips
# Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
# Set-PSReadLineKeyHandler -Key Tab -Function Complete

Set-PSReadLineOption -BellStyle None

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

Set-PSReadLineOption -CommandValidationHandler {
  param([System.Management.Automation.Language.CommandAst]$CommandAst)
}
Set-PSReadLineKeyHandler -Chord Enter -Function ValidateAndAcceptLine

Set-PSReadLineKeyHandler -Chord '"', "'" `
  -BriefDescription SmartInsertQuote `
  -LongDescription "Insert paired quotes if not already on a quote" `
  -ScriptBlock {
  param($key, $arg)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  if ($line.Length -gt $cursor -and $line[$cursor] -eq $key.KeyChar) {
    # Just move the cursor
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
  }
  else {
    # Insert matching quotes, move cursor to be in between the quotes
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)" * 2)
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
  }
}

Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  dotnet complete --position $cursorPosition "$commandAst" | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PsReadLineChordProvider 'Ctrl+f' -PsReadLineChordReverseHistory 'Ctrl+r'

# Function
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue
  | Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function touch {
  Param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )
  if (Test-Path -LiteralPath $Path) {
    (Get-Item -Path $Path).LastWriteTime = Get-Date
  }
  else {
    New-Item -Type File -Path $Path
  }
}

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
  $Local:word = $wordToComplete.Replace('"', '""')
  $Local:ast = $commandAst.ToString().Replace('"', '""')
  winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
  }
}

#region Smart Insert/Delete

# The next four key handlers are designed to make entering matched quotes
# parens, and braces a nicer experience.  I'd like to include functions
# in the module that do this, but this implementation still isn't as smart
# as ReSharper, so I'm just providing it as a sample.

# Set-PSReadLineKeyHandler -Key '"',"'" `
#                          -BriefDescription SmartInsertQuote `
#                          -LongDescription "Insert paired quotes if not already on a quote" `
#                          -ScriptBlock {
#     param($key, $arg)

#     $quote = $key.KeyChar

#     $selectionStart = $null
#     $selectionLength = $null
#     [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

#     $line = $null
#     $cursor = $null
#     [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

#     # If text is selected, just quote it without any smarts
#     if ($selectionStart -ne -1)
#     {
#         [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.SubString($selectionStart, $selectionLength) + $quote)
#         [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
#         return
#     }

#     $ast = $null
#     $tokens = $null
#     $parseErrors = $null
#     [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

#     function FindToken
#     {
#         param($tokens, $cursor)

#         foreach ($token in $tokens)
#         {
#             if ($cursor -lt $token.Extent.StartOffset) { continue }
#             if ($cursor -lt $token.Extent.EndOffset) {
#                 $result = $token
#                 $token = $token -as [StringExpandableToken]
#                 if ($token) {
#                     $nested = FindToken $token.NestedTokens $cursor
#                     if ($nested) { $result = $nested }
#                 }

#                 return $result
#             }
#         }
#         return $null
#     }

#     $token = FindToken $tokens $cursor

#     # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
#     if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
#         # If we're at the start of the string, assume we're inserting a new string
#         if ($token.Extent.StartOffset -eq $cursor) {
#             [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
#             [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
#             return
#         }

#         # If we're at the end of the string, move over the closing quote if present.
#         if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
#             [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
#             return
#         }
#     }

#     if ($null -eq $token -or
#         $token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
#         if ($line[0..$cursor].Where{$_ -eq $quote}.Count % 2 -eq 1) {
#             # Odd number of quotes before the cursor, insert a single quote
#             [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
#         }
#         else {
#             # Insert matching quotes, move cursor to be in between the quotes
#             [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
#             [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
#         }
#         return
#     }

#     # If cursor is at the start of a token, enclose it in quotes.
#     if ($token.Extent.StartOffset -eq $cursor) {
#         if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or 
#             $token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
#             $end = $token.Extent.EndOffset
#             $len = $end - $cursor
#             [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.SubString($cursor, $len) + $quote)
#             [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
#             return
#         }
#     }

#     # We failed to be smart, so just insert a single quote
#     [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
# }

Set-PSReadLineKeyHandler -Key '(', '{', '[' `
  -BriefDescription InsertPairedBraces `
  -LongDescription "Insert matching braces" `
  -ScriptBlock {
  param($key, $arg)

  $closeChar = switch ($key.KeyChar) {
    <#case#> '(' { [char]')'; break }
    <#case#> '{' { [char]'}'; break }
    <#case#> '[' { [char]']'; break }
  }

  $selectionStart = $null
  $selectionLength = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    
  if ($selectionStart -ne -1) {
    # Text is selected, wrap it in brackets
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.SubString($selectionStart, $selectionLength) + $closeChar)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
  }
  else {
    # No text is selected, insert a pair
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
  }
}

Set-PSReadLineKeyHandler -Key ')', ']', '}' `
  -BriefDescription SmartCloseBraces `
  -LongDescription "Insert closing brace or skip" `
  -ScriptBlock {
  param($key, $arg)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  if ($line[$cursor] -eq $key.KeyChar) {
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
  }
  else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
  }
}

Set-PSReadLineKeyHandler -Key Backspace `
  -BriefDescription SmartBackspace `
  -LongDescription "Delete previous character or matching quotes/parens/braces" `
  -ScriptBlock {
  param($key, $arg)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

  if ($cursor -gt 0) {
    $toMatch = $null
    if ($cursor -lt $line.Length) {
      switch ($line[$cursor]) {
        <#case#> '"' { $toMatch = '"'; break }
        <#case#> "'" { $toMatch = "'"; break }
        <#case#> ')' { $toMatch = '('; break }
        <#case#> ']' { $toMatch = '['; break }
        <#case#> '}' { $toMatch = '{'; break }
      }
    }

    if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
      [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
    }
    else {
      [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
    }
  }
}

#endregion Smart Insert/Delete


# Default location
# Set-Location "F:\"

#region Alias

Set-Alias -Name ll -Value eza
Set-Alias -Name vim -Value nvim
Set-Alias -Name grep -Value rg
# Set-Alias -Name touch -Value New-Item
Set-Alias -Name top -Value btm
Set-Alias -Name j -Value z
# Set-Alias -Name cat -Value bat

#endregion Alias
