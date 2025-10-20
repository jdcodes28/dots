#!/usr/bin/env nu

export def get-gnome-color-scheme [] {
  dconf read /org/gnome/desktop/interface/color-scheme | str trim
}

export def file-replace [
    file:         string,
    line_has:     string,
    target:       string,
    replacement:  string
] {
    open --raw $file | lines | each { |line|
        if ($line | str contains $line_has) {
            $line | str replace $target $replacement
        } else {
            $line
        }
    } | save --force $file
}

