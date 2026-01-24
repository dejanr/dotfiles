---
name: skill-discovery
description: Discover agent skills on GitHub. Use when user asks to find new skills, search for skills, explore skill repositories, or wants to see trending/popular skills.
---

# Skill Discovery

Find agent skills on GitHub using `gh` CLI. Skills work across multiple harnesses (Claude Code, Codex, Gemini CLI, Pi, etc.) as they follow the same SKILL.md format.

## Workflow

1. Search repos by topic to find skill collections
2. For awesome lists: fetch README and extract skill links
3. For skill repos: list directories containing SKILL.md
4. Build searchable catalog at `/tmp/skills-catalog.md`
5. Search/filter based on user query

## Find skill repos

```bash
gh search repos --topic=claude-skills --sort=stars --limit=30 --json fullName,description
gh search repos --topic=codex-skills --sort=stars --limit=20 --json fullName,description
gh search repos --topic=gemini-skills --sort=stars --limit=20 --json fullName,description
gh search repos --topic=skill-md --sort=stars --limit=20 --json fullName,description
gh search repos --topic=agent-skills --sort=stars --limit=20 --json fullName,description
gh search repos --topic=claude-code-skills --sort=stars --limit=20 --json fullName,description
gh search repos --topic=gemini-cli-skills --sort=stars --limit=20 --json fullName,description
```

## Find repos with SKILL.md files

Search GitHub code for actual SKILL.md files (finds repos not tagged with topics):

```bash
# Find repos containing SKILL.md files, then fetch stars via GraphQL (single query)
repos=$(gh search code "filename:SKILL.md" --limit=50 --json repository | jq -r '.[].repository.nameWithOwner' | sort -u)

# Build GraphQL query to get stars for all repos at once
query="{ "
i=0
for repo in $repos; do
  owner="${repo%/*}"
  name="${repo#*/}"
  query+="r$i: repository(owner: \"$owner\", name: \"$name\") { nameWithOwner stargazerCount description } "
  ((i++))
done
query+="}"

gh api graphql -f query="$query" --jq '.data | to_entries[] | "\(.value.nameWithOwner) ★\(.value.stargazerCount) - \(.value.description // "no desc")"' | sort -t'★' -k2 -rn
```

## Build catalog from awesome lists

For repos with "awesome" in name, fetch README:

```bash
gh api "repos/<owner>/<repo>/contents/README.md" --jq '.content' | base64 -d >> /tmp/skills-catalog.md
```

## List skills in a collection repo

For repos with skills directories:

```bash
# Find skills directory (skills/, scientific-skills/, etc.)
gh api repos/<owner>/<repo>/contents --jq '.[].name'

# List individual skills
gh api repos/<owner>/<repo>/contents/<skills-dir> --jq '.[].name'
```

## Search catalog

```bash
grep -i "<keyword>" /tmp/skills-catalog.md -B2 -A1
```

## View skill contents

```bash
gh api repos/<owner>/<repo>/contents/<path>/SKILL.md --jq '.content' | base64 -d
```

## Install skill

```bash
gh repo clone <owner>/<repo> /tmp/<repo>
cp -r /tmp/<repo>/skills/<skill-name> ~/.pi/agent/skills/
```

## Output

Show matching skills as table: | Repository | Description |

After results, offer:

1. View a specific skill's SKILL.md
2. Install a skill to `~/.pi/agent/skills/`
3. Search for different keywords
