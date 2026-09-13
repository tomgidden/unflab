# askclaude -- one-shot questions to Claude from the command line.
#
# In ~/.config/fish/functions/ fish autoloads this by filename; sourced
# from config.fish it is defined immediately. Either works.
function askclaude --description 'Ask Claude a one-off question'
    set -l message (jq -n --arg content "$argv" '{role: "user", content: $content}')
    or return
    ant messages create \
        --model claude-haiku-4-5 \
        --max-tokens 1024 \
        --message "$message" | jq -r '.content[0].text'
end
