askclaude () {
  emulate -L zsh
  setopt local_options null_glob

  local message=$(jq -n --arg content "$*" '{role: "user", content: $content}')
  ant messages create \
    --model claude-haiku-4-5 \
    --max-tokens 1024 \
    --message "$message" | jq -r '.content[0].text'
}
