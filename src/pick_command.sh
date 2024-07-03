go_to_prompt="Go to n or alias: "
entries=$(tmt list)
if [ $(which fzf) ]; then
    target=$(echo "$entries" | fzf | cut -d'|' -f1)
else
    cat | read -p "$go_to_prompt" target
fi
tmt go $target
