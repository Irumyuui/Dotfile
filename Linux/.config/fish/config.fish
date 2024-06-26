if status is-interactive
    # Commands to run in interactive sessions can go here
    set -gx fish_greeting
    set -gx EDITOR nvim
    abbr ls eza
    abbr la eza -a
    abbr ll eza -l
    abbr lt eza -T

    zoxide init fish | source
    starship init fish | source
    atuin init fish | source
end
