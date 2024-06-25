# TakeMeThere !

## Description

TakeMeThere simplifies navigation to frequently visited directories using user-defined aliases stored in a user defined file (default: `~/.takemethere`).

 - Quickly access directories by alias (`tmt work`) or sequential order (`tmt 1`, `tmt 2`, etc.).
 - Easily manage, reorder, and edit aliases through the CLI or using your preferred text editor.

## Install

1. Clone this repo or download the `takemethere.sh` script directly. (Grab the https link if need be.)
   ```bash
   git clone git@github.com:codevogel/takemethere.git
   ```
3. Make the file executable
   ```bash
   sudo chmod +x where/you/put/your/takemethere.sh
   ```
5. Add an alias of your liking to `.bashrc` / `.zshrc` to source the script (for other shells, do something to the same extent) 
   ```bash
   alias tmt='source where/you/put/your/takemethere.sh'
   ```
6. Restart your shell or `source` your `.bashrc` / `.zshrc` (for other shells, again, do something to the same extent.
   ```bash
   source ~/.bashrc
   ```
8. Call TakeMeThere
   ```bash
   tmt
   ```

## Options

```
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
```

### Note

  - Line numbers and aliases are 1-indexed.
  - Use quotes around alias:path entries containing spaces.

## Examples
```
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
```

## Configuration

If for whatever reason you want the `.takemethere` file to live at some other place than `~`, just update the `$FILE` variable in `takemethere.sh`
