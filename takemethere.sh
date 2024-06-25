#!/bin/bash

# Path to the file that holds directory paths
FILE="$HOME/.takemethere"

# Function to edit the .takemethere file
edit_entries() {
    if [ -z "$EDITOR" ]; then
        echo "EDITOR variable is not set."
        return 1
    fi
    $EDITOR "$FILE"
}

# Function to list the contents of the .takemethere file
list_entries() {
    # Get line count of $FILE
    local line_count=$(wc -l < "$FILE")
    if [ "$line_count" -eq 0 ]; then
        echo "No entries found in $FILE"
        return 1
    fi
    # Use awk to print lines with the appropriate padding
    awk -v width="${#line_count}" '{printf "%" width "d | %s\n", NR, $0}' "$FILE"
}

print_options() {
    cat <<EOF
Options:
  n                   Change to the directory at line n (1-indexed).
  alias               Change to the directory associated with 'alias'.
  -h, --help          Display an extended help message.
  -a, --add           Add a new path or alias:path entry to the file.
                        -a <path>
                        -a <alias> <path>
  -c, --change        Change alias or directory path by alias or line.
                        -c <alias|n> <new_alias> <new_path>
                        -c <alias|n> <new_path>
  -d, --delete        Delete an alias or line by alias or line number.
                        -d <alias|n>
  -D, --delete-all    Delete all entries in the .takemethere file.
                      Asks for confirmation first, unless forced.
                        -D [-f]
  -e, --edit          Open the ~/.takemethere file with your \$EDITOR.
                      (This is powerful for quick rearranging of entries!)
  -l, --list          Display the current contents of the .takemethere file.
  --examples          Display examples of how to use the script.
EOF
}

print_examples() {
    cat <<EOF
Examples:
  tmt 3                         # Change to directory on line 3
  tmt my_alias                  # Change to directory associated with 'my_alias'

  tmt -a /some/dir              # Add path '/some/dir' as the last entry.
  tmt -a foo /some/dir          # Add alias 'foo' for path '/some/dir' as the last entry

  tmt -c 1 /some/dir            # Change line 1 so it points to path '/some/dir'
  tmt -c 1 foo /some/dir        # Change line 1 so alias 'foo' points to path '/some/dir'
  tmt -c foo /some/dir          # Change alias 'foo' so it points to path '/some/dir'
  tmt -c foo bar /some/dir      # Change alias 'foo' to 'bar' and point it to '/some/dir'

  tmt -d 3                      # Delete entry on line 3
  tmt -d foo                    # Delete entry associated with alias 'foo'

  tmt -e                        # Edit the .takemethere file
  tmt -l                        # List current entries in .takemethere
EOF
}

print_help() {
    cat <<EOF
Usage: tmt [OPTIONS] [ARGUMENTS]

Description: TakeMeThere simplifies navigation to frequently visited directories using
   user-defined aliases stored in a user defined file (default: ~/.takemethere).
   Quickly access directories by alias (tmt work) or sequential order (tmt 1, tmt 2, etc.).
   Easily manage, reorder, and edit aliases through the CLI or using your preferred text editor.

$(print_options)

Note:
  - Line numbers and aliases are 1-indexed.
  - Use quotes around alias:path entries containing spaces.
EOF
}

# Argument is an alias when it is not a number group
is_digits() {
    case $1 in
        *[!0-9]*) return 1 ;; # Not all digits
        *) return 0 ;; # All digits
    esac
}

alias_is_valid() {
    local new_alias=$1
    if is_digits "$new_alias"; then
        echo "Alias '$new_alias' can not only contain numbers."
    elif echo "$new_alias" | grep -q ":" || echo "$new_alias" | grep -q "/"; then
        echo "Alias '$new_alias' can not contain colons."
    elif grep -q "^$new_alias:" "$FILE"; then
        echo "Alias '$new_alias' is already used."
    else
        return 0
    fi
    return 1
}

path_is_valid() {
    local _path=$1 # Avoid overwriting $path
    if [ ! -d "$_path" ]; then
        echo "Path '$_path' does not exist or is not a directory."
        return 1
    fi
    return 0
}

add_entry() {
    case $# in
        1)
            local _path=$1
            if path_is_valid $_path; then
                if [ "$_path" = "." ]; then
                    _path=$(pwd)
                fi
                echo "$_path" >> "$FILE"
                echo "Added entry:"
                echo "$(wc -l < "$FILE") | $_path"
                return 0
            fi
            ;;
        2)
            local _alias=$1
            local _path=$2
            if alias_is_valid $_alias && path_is_valid $_path; then
                if [ "$_path" = "." ]; then
                    _path=$(pwd)
                fi
                echo "$_alias:$_path" >> "$FILE"
                echo "Added entry:"
                echo "$(wc -l < "$FILE") | $_alias:$_path"
                return 0
            fi
            ;;
        *)
            echo "Invalid number of arguments."
            echo "Usage: tmt --add|-a [<alias>] <path>"
            echo "See 'tmt --help' for more information."
            ;;
    esac
    return 1
}

change_entry() {
    local target=$1
    local new_entry=$2

    if is_digits "$target"; then
        # Change by line number
        local line_number=$target
        local line_count=$(wc -l < "$FILE")
        if [ $line_number -lt 0 -o $line_number -gt $line_count ]; then
            echo "Line number '$line_number' does not exist."
            return 1
        fi
    else
        # Get line number of alias
        local line_number=$(grep -n "^$target:" "$FILE" | cut -d: -f1)
        if [ -z "$line_number" ]; then
            echo "Alias '$target' does not exist."
            return 1
        fi
        local new_entry="$target:$new_entry"
    fi

    sed -i "${line_number}s|.*|$new_entry|" "$FILE"
    echo "Entry updated:"
    echo "$line_number | $new_entry"
}

change() {
    local target=$1
    case $# in
        2)
            local _path=$2
            if path_is_valid $_path; then
                change_entry $target $_path
                return 0
            fi
            ;;
        3)
            local _alias=$2
            local _path=$3
            if alias_is_valid $_alias && path_is_valid $_path; then
                change_entry $target "$_alias:$_path"
                return 0
            fi
            ;;
        *)
            echo "Invalid number of arguments."
            echo "Usage: tmt --change|-c <alias|n> [<new_alias>] <new_path>"
            echo "See 'tmt --help' for more information."
            return 1
            ;;
    esac
}

delete_all_entries() {
    local force=$2
    if [ "$force" != "-f" ]; then
        echo -n "Are you sure you want to delete all entries in $FILE? (y/n):"
        read "Are you sure you want to delete all entries in $FILE? (y/n): " confirm
        [[ ! "$confirm" =~ ^[yY]$ ]] && echo "Aborted." && return 1
    fi
    rm "$FILE"
    echo "Deleted $FILE"
    return 0
}

change_to_directory() {
    local target=$1
    # cd to the directory
    if is_digits "$target"; then
        local line_number=$target
        local line=$(sed -n "${line_number}p" "$FILE")
        local _path=$(echo "$line" | cut -d: -f2)
        cd "$_path"
    else
        local _alias=$target
        local line=$(grep "^$_alias:" "$FILE")
        local _path=$(echo "$line" | cut -d: -f2)
        cd "$_path"
    fi
}

delete_entry() {
    local target=$1
    if is_digits "$target"; then
        # Delete by line number
        local line_number=$target
        local line_count=$(wc -l < "$FILE")
        if [ $line_number -lt 1 ]; then
            echo "Line number '$line_number' must be greater than 0. (There are $line_count lines)."
            return 1
        elif [ $line_number -gt $line_count ]; then
            echo "Line number '$line_number' is out of range. (There are $line_count lines)."
            return 1
        fi
        sed -i "${line_number}d" "$FILE"
        echo "Deleted line '$line_number'"
    else
        # Delete by alias
        if grep -q "^$target:" "$FILE"; then
            sed -i "/^$target:/d" "$FILE"
            echo "Deleted alias '$target'"
        else
            echo "Not removing alias '$target' because it does not exist."
            return 1
        fi
    fi
}

###########################################################################
############## Main script logic ##########################################
###########################################################################

# Create the file if it does not exist
if [ ! -f "$FILE" ]; then
    touch "$FILE"
fi

# Reject invalid arg count
if [ "$#" -lt 1 ]; then
    list_entries
    echo -n "Go to line number or alias: "
    read target
    change_to_directory "$target"
    return 0
elif [ "$#" -gt 4 ]; then
    echo "Usage: tmt [OPTIONS] [ARGUMENTS]"
    echo ""
    print_options
    return 1
fi

local option=$1
local args=("${@:2}")

case "$option" in
    --help|-h)
        print_help
        ;;
    --add|-a)
        add_entry $args
        ;;
    --change|-c)
        change $args
        ;;
    --delete|-d)
        delete_entry $args
        ;;
    --delete-all|-D)
        delete_all_entries $args
        ;;
    --edit|-e)
        edit_entries
        ;;
    --list|-l)
        list_entries
        ;;
    --examples)
        print_examples
        ;;
    *)
        # Option was actually an argument
        if [ "$#" -ne 1 ]; then
            echo "$1 is not a valid option. "
            echo "Usage: tmt [n|alias]"
            echo "See 'tmt --help' for more information."
            return 1
        fi
        change_to_directory "$option"
        ;;
esac

