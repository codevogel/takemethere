#!/bin/bash

# Path to the file that holds directory paths
FILE="$HOME/.takemethere"

# Function to edit the .takemethere file
edit_entries() {
    ${EDITOR:-vi} "$FILE"
}

# Function to list the contents of the .takemethere file
list_entries() {
    # Get line count of $FILE
    local line_count=$(wc -l < "$FILE")
    [ "$line_count" -eq 0 ] \
        && echo "No entries found in $FILE" \
        && return 1
    # Print lines with the appropriate padding
    awk -v width="${#line_count}"  \
        '{printf "%" width "d | %s\n", NR, $0}' "$FILE"
}

# Argument is an alias when it is not a number group
is_digits() {
    [[ $1 =~ ^[0-9]+$ ]]
}

alias_is_valid() {
    local new_alias=$1
    is_digits "$new_alias" \
        && echo "Alias '$new_alias' can not only contain numbers." \
        && return 1
    [[ "$new_alias" =~ [:\/] ]] \
        && echo "Alias '$new_alias' can not contain ':' or '/'." \
        && return 1
    grep -q "^$new_alias:" "$FILE" \
        && echo "Alias '$new_alias' is already used." \
        && return 1
    return 0
}
# Validate and get the absolute path
get_valid_absolute_path() {
    local _path
    _path=$(cd "$1" > /dev/null 2>&1 && pwd)
    [ -z "$_path" ] \
        && echo "Path '$1' does not point to an existing directory." >&2  \
        && return 1
    echo "$_path"
}

# Add an entry to the file
add_entry() {
    local _path _alias
    case $# in
        1)  _path=$(get_valid_absolute_path "$1") || return 1
            echo "$_path" >> "$FILE" ;;
        2)  _alias=$1
            _path=$(get_valid_absolute_path "$2") || return 1
            alias_is_valid "$_alias" || return 1
            echo "$_alias:$_path" >> "$FILE" ;;
        *)  echo "Invalid number of arguments." >&2
            echo "Usage: tmt --add|-a [<alias>] <path>" >&2
            echo "See 'tmt --help' for more information." >&2
            return 1
            ;;
    esac
    echo "Added entry:"
    echo "$(wc -l < "$FILE") | $(tail -n 1 "$FILE")"
}

change_entry() {
    local target=$1 new_entry=$2 line_number
    if is_digits "$target"; then
        line_number=$target
        # Validate line number (1-indexed and within range)
        (( line_number < 1 || line_number > $(wc -l < "$FILE"))) \
            && echo "Line number '$line_number' does not exist." \
            && return 1
    else
        line_number=$(grep -n "^$target:" "$FILE" | cut -d: -f1)
        [ -z "$line_number" ] \
            && echo "Alias '$target' does not exist." \
            &&  return 1
        new_entry="$target:$new_entry"
    fi
    sed -i "${line_number}s|.*|$new_entry|" "$FILE"
    echo "Entry updated:"
    echo "$line_number | $new_entry"
}

change() {
    local target=$1 _path _alias
    case $# in
        2) _path=$(get_valid_absolute_path "$2") || return 1
            change_entry "$target" "$_path" ;;
        3) _alias=$2
            _path=$(get_valid_absolute_path "$3") || return 1
            alias_is_valid "$_alias" || return 1
            change_entry "$target" "$_alias:$_path" ;;
        *) echo "Invalid number of arguments."
            echo "Usage: tmt --change|-c <alias|n> [<new_alias>] <new_path>"
            echo "See 'tmt --help' for more information."
            return 1 ;;
    esac
}

delete_all_entries() {
    local force=$2
    if [ "$force" != "-f" ]; then
        echo -n "Are you sure you want to delete all entries in $FILE? (y/n): "
        read confirm
        [[ ! "$confirm" =~ ^[yY]$ ]] && echo "Aborted." && return 1
    fi
    rm "$FILE" && echo "Deleted $FILE"
}

line_nr_is_valid() {
    [ $line_number -lt 1 ] \
        && echo "Line number '$line_number' must be greater than 0. " \
        "(There are $line_count lines)." \
        && return 1
    [ $line_number -gt $line_count ] \
        && echo "Line number '$line_number' is out of range." \
        "(There are $line_count lines)." \
        && return 1
}

change_to_directory() {
    [ "$(wc -l < "$FILE")" -eq 0 ] \
        && echo "No entries found in $FILE" \
        && return 1
    local alias_or_num=$1 dir
    if is_digits "$alias_or_num"; then
        dir=$(sed -n "${alias_or_num}p" "$FILE" | cut -d: -f2-)
        [ -z "$dir" ] \
            && echo "Entry '$alias_or_num' is out of range!" \
            && echo "Hint: There are currently only $(wc -l < "$FILE") entries. Use 'tmt -l' to list them all." \
            && return 1
    else
        dir=$(grep "^$alias_or_num:" "$FILE" | cut -d: -f2-)
        [ -z "$dir" ] \
            && echo "Alias '$alias_or_num' does not exist." \
            && return 1
    fi
    if [ -d "$dir" ]; then
        cd "$dir"
    else
        echo "Alias or line number '$alias_or_num' points to path '$dir', which does not exist."
        return 1
    fi
}

delete_entry() {
    delete_entry() {
        [ "$(wc -l < "$FILE")" -eq 0 ] \
            && echo "No entries found in $FILE" \
            && return 1
        local alias_or_num=$1
        is_digits "$alias_or_num" \
            && sed -i "${alias_or_num}d" "$FILE" \
            || sed -i "/^$alias_or_num:/d" "$FILE"
    }
}

print_options() {
    cat <<EOF
Options:
  n                      Change to the directory at line n (1-indexed).
  alias                  Change to the directory associated with 'alias'.
  -h, --help             Display an extended help message.
  -a, --add              Add a new path or alias:path entry to the file.
                           -a <path>
                           -a <alias> <path>
  -c, --change           Change alias or directory path by alias or line.
                           -c <alias|n> <new_alias> <new_path>
                           -c <alias|n> <new_path>
  -d, --delete           Delete an alias or line by alias or line number.
                           -d <alias|n>
  -D, --delete-all       Delete all entries in the .takemethere file.
                         Asks for confirmation first, unless forced.
                           -D [-f]
  -e, --edit             Open the ~/.takemethere file with your \$EDITOR.
                         (This is powerful for quick rearranging of entries,
                          so you can go to directories simply by number!)
  -l, --list             Display the current contents of the .takemethere file.
  --examples             Display examples of how to use the script.
EOF
}

print_examples() {
    cat <<EOF
Examples:
  tmt                         List all entries in .takemethere and then
                              prompt to go to an entry.
                               -> Much cooler with 'fzf' installed!

  tmt my_alias                Change to directory associated with 'my_alias'

  tmt 3                       Change to directory listed on line 3
                               in .takemethere

  tmt -a /some/dir            Add path '/some/dir' as the last entry (n).
                              Result:
                               tmt n     ->    cd /some/dir

  tmt -a foo /some/dir        Adds alias 'foo' for path '/some/dir' as the last
                               entry (n).
                              Result:
                               tmt foo   ->    cd /some/dir
                               tmt n     ->    cd /some/dir

  tmt -c 2 /some/dir          Overwrite entry 2 so it points to '/some/dir'
                              Result:
                               tmt 2     ->    cd /some/dir


  tmt -c 1 foo /some/dir      Overwrites entry 1 and stores an entry that makes
                                alias 'foo' point to '/some/dir'
                              Result:
                               tmt foo   ->    cd /some/dir
                               tmt 1     ->    cd /some/dir

  tmt -c foo /some/dir        Overwrites the path of the entry associated with
                               alias 'foo' so it now points to path '/some/dir'.
                              This will also list the entry number that was
                               changed (n)
                              Result:
                               tmt foo   ->     cd /some/dir
                               tmt n     ->     cd /some/dir

  tmt -c foo bar /some/dir    Overwrites the entry associated with alias 'foo'
                               with an entry that makes alias 'bar' point to
                               path '/some/dir'
                              This will also list the entry number that was
                               changed (n)
                              Result:
                                tmt bar   ->    cd /some/dir
                                tmt n     ->    cd /some/dir

  tmt -d 3                    Delete entry 3
  tmt -d foo                  Delete entry associated with alias 'foo'

  tmt -e                      Edit the .takemethere file with \$EDITOR

  tmt -l                      List current entries in .takemethere
EOF
}

print_help() {
    cat <<EOF
Usage: tmt [OPTIONS] [ARGUMENTS]

Description:
  TakeMeThere simplifies navigation to frequently visited directories using
   user-defined aliases stored in a user defined file (default: ~/.takemethere).
  Because TakeMeThere decouples your aliases from your shell environment,
   alias conflicts later down the line are prevented.
  It also allows you to quickly access directories by number, making it easy to
   navigate to directories without having to remember the alias.

Key Features:
  -> Quickly access directories by alias (tmt work) or number
  -> Easily manage, reorder, and edit aliases through the CLI or using your
      preferred text editor.
  -> Optional fzf integration for fuzzy find selection of your directories.

$(print_options)

Note:
  - Line numbers and aliases are 1-indexed.
  - Use quotes around alias:path entries containing spaces.
EOF
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
    if [ "$(wc -l < "$FILE")" -eq 0 ]; then
        echo "No entries found in $FILE"
        echo "To create your first entry, see 'tmt --help' and look at " \
            "the --add option."
        return 1
    fi

    if $(which fzzf >/dev/null 2>&1); then
        local entry=$(list_entries | fzf --height 30% --reverse --ansi \
            --prompt="Go to line number or alias: ")
        local target=$( echo $entry | cut -d '|' -f1 | xargs)
        change_to_directory "$target"
        return 0
    else
        list_entries
        echo -n "Go to line number or alias: "
        read target
        change_to_directory "$target"
        return 0
    fi
elif [ "$#" -gt 4 ]; then
    echo "Usage: tmt [OPTIONS] [ARGUMENTS]"
    echo ""
    print_options
    return 1
fi

local option=$1
local args=("${@:2}")

case "$option" in
    --help|-h) print_help ;;
    --add|-a) add_entry $args ;;
    --change|-c) change $args ;;
    --delete|-d) delete_entry $args ;;
    --delete-all|-D) delete_all_entries $args ;;
    --edit|-e) edit_entries ;;
    --list|-l) list_entries ;;
    --examples) print_examples ;;
    *)  if [ "$#" -ne 1 ]; then
            echo "$1 is not a valid option. "
            echo "Usage: tmt [n|alias]"
            echo "See 'tmt --help' for more information."
            return 1
        fi
        # Option was actually an argument
        change_to_directory "$option" ;;
esac

