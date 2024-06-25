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
    echo "Options:"
    echo "  n                   Change to the directory at line n (1-indexed)."
    echo "  alias               Change to the directory associated with 'alias'."
    echo "  -h, --help          Display an extended help message."
    echo "  -a, --add           Add a new path or alias:path entry to the file."
    echo "                        -a <path>"
    echo "                        -a <alias> <path>"
    echo "  -c, --change        Change alias or directory path by alias or line."
    echo "                        -c <alias|n> <new_alias> <new_path>"
    echo "                        -c <alias|n> <new_path>"
    echo "  -d, --delete        Delete an alias or line by alias or line number."
    echo "                        -d <alias|n>"
    echo "  -D, --delete-all    Delete all entries in the .takemethere file."
    echo "                      Asks for confirmation first, unless forced."
    echo "                        -D [-f]"
    echo "  -e, --edit          Open the ~/.takemethere file with your \$EDITOR."
    echo "                      (This is powerful for quick rearranging of entries!)"
    echo "  -l, --list          Display the current contents of the .takemethere file."
}

print_examples() {
    echo "Examples:"
    echo "  tmt 3                         # Change to directory on line 3"
    echo "  tmt my_alias                  # Change to directory associated with 'my_alias'"
    echo ""
    echo "  tmt -a /some/dir              # Add path '/some/dir' as the last entry."
    echo "  tmt -a foo /some/dir          # Add alias 'foo' for path '/some/dir' as the last entry"
    echo ""
    echo "  tmt -c 1 /some/dir            # Change line 1 so it points to path '/some/dir'"
    echo "  tmt -c 1 foo /some/dir        # Change line 1 so alias 'foo' points to path '/some/dir'"
    echo "  tmt -c foo /some/dir          # Change alias 'foo' so it points to path '/some/dir'"
    echo "  tmt -c foo bar /some/dir      # Change alias 'foo' to 'bar' and point it to '/some/dir'"
    echo ""
    echo "  tmt -d 3                      # Delete entry on line 3"
    echo "  tmt -d foo                    # Delete entry associated with alias 'foo'"
    echo ""
    echo "  tmt -e                        # Edit the .takemethere file"
    echo "  tmt -l                        # List current entries in .takemethere"
}

print_help() {
    echo "Usage: tmt [OPTIONS] [ARGUMENTS]"
    echo ""
    echo "Aliases: tmt, tkme, takemethere"
    echo ""
    echo "Description: TakeMeThere simplifies navigation to frequently visited directories using user-defined aliases stored in a user defined file (default: ~/.takemethere). Quickly access directories by alias (tmt work) or sequential order (tmt 1, tmt 2, etc.). Easily manage, reorder, and edit aliases through the CLI or using your preferred text editor."
    echo ""
    print_options
    echo ""
    print_examples
    echo ""
    echo "Note:"
    echo "  - Line numbers and aliases are 1-indexed."
    echo "  - Use quotes around alias:path entries containing spaces."
    return 1
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
        echo "Alias $new_alias can not only contain numbers."
        return 1
    elif echo "$new_alias" | grep -q ":"; then
        echo "Alias $new_alias can not contain colons."
        return 1
    elif grep -q "^$new_alias:" "$FILE"; then
        echo "Alias $new_alias is already used."
        return 1
    fi
    return 0
}

path_is_valid() {
    local _path=$1 # Avoid overwriting $path
    if [ ! -d "$_path" ]; then
        echo "Path $_path does not exist or is not a directory."
        return 1
    fi
    return 0
}



add_entry() {
    case $# in
        1)
            local _path=$1
            if path_is_valid $_path; then
                echo "$_path" >> "$FILE"
                return 0
            fi
            return 1
            ;;
        2)
            local _alias=$1
            local _path=$2
            if alias_is_valid $_alias && path_is_valid $_path; then
                echo "$_alias:$_path" >> "$FILE"
                return 0
            fi
            return 1
            ;;
    esac
    echo "Invalid number of arguments."
    echo "Usage: tmt --add|-a [<alias>] <path>"
    echo "See 'tmt --help' for more information."
    return 1
}

change_entry() {
    local target=$1
    local new_entry=$2

    if ! is_digits "$target"; then
        # Get line number of alias
        local line_number=$(grep -n "^$target:" "$FILE" | cut -d: -f1)
        if [ -z "$line_number" ]; then
            echo "Alias $target does not exist."
            return 1
        fi
        local new_entry="$target:$new_entry"
    else
        # Change by line number
        local line_number=$target
        local line_count=$(wc -l < "$FILE")
        if [ $line_number -lt 0 -o $line_number -gt $line_count ]; then
            echo "Line number $line_number does not exist."
            return 1
        fi
    fi

    sed -i "${line_number}s|.*|$new_entry|" "$FILE"
    echo "Entry updated:"
    echo "$line_number | $new_entry"
}


change() {
    case $# in
        2)
            local target=$1
            local _path=$2
            if path_is_valid $_path; then
                change_entry $target $_path
                return 0
            fi
            ;;
        3)
            local target=$1
            local _alias=$2
            local _path=$3
            if alias_is_valid $_alias && path_is_valid $_path; then
                change_entry $target "$_alias:$_path"
                return 0
            fi
            ;;
    esac
    echo "Invalid number of arguments."
    echo "Usage: tmt --change|-c <alias|n> [<new_alias>] <new_path>"
    echo "See 'tmt --help' for more information."
    return 1
}

delete_all_entries() {
    # Ask for confirmation unless forced
    if [ "$2" != "-f" ]; then
        echo "Are you sure you want to delete all entries in $FILE? (y/n)"
        read -r confirm
        if [[ "$confirm" != [yY] ]]; then
            echo "Aborted."
            return 1
        fi
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
            echo "Line number must be greater than 0. (There are $line_count lines)."
            return 1
        elif [ $line_number -gt $line_count ]; then
            echo "Line number $line_number is out of range (There are $line_count lines)."
            return 1
        fi
        sed -i "${line_number}d" "$FILE"
        echo "Deleted line $line_number"
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
if [ "$#" -lt 1 -o "$#" -gt 4 ]; then
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

