# askclaude -- one-shot questions to Claude from the command line.
#
# In ~/.config/fish/functions/ fish autoloads this by filename; sourced
# from config.fish it is defined immediately. Either works.
function askclaude --description 'Ask Claude a one-off question'
    if test (count $argv) -eq 0
        echo 'usage: askclaude <question>' >&2
        return 2
    end

    set -l message (jq -n --arg content "$argv" '{role: "user", content: $content}')
    or return
    ant messages create \
        --model claude-haiku-4-5 \
        --max-tokens 1024 \
        --message "$message" | jq -r '.content[0].text'
end
