go_to_prompt="Go to n or alias: "
entries=$(tmt list)
if [[ ! ${args[--no-fzf]} && $(which fzf) ]]; then
    target=$(echo "$entries" | fzf --prompt "$go_to_prompt" --height 5 --reverse | cut -d'|' -f1)
else
    tmt list && read -p "$go_to_prompt" target
fi
echo $target
