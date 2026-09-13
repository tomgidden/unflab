# askclaude -- one-shot questions to Claude from the command line.
#
# Source this from ~/.bashrc; bash has no autoload, so it is defined
# when the file is sourced rather than on first use.
askclaude() {
  local message
  message=$(jq -n --arg content "$*" '{role: "user", content: $content}') || return
  ant messages create \
    --model claude-haiku-4-5 \
    --max-tokens 1024 \
    --message "$message" | jq -r '.content[0].text'
}
