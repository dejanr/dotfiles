---
name: chat-to-skill
description: Convert current chat session into a reusable skill. Use when user says "/chat-to-skill", "save this as skill", "create skill from chat", "turn this into a skill", or wants to preserve learnings from the conversation as long-term memory.
---

# Chat to Skill

Transform conversation history into reusable skills — long-term memory for Claude.

## Process

### 1. Analyze Dialog

Scan the entire conversation to identify:

- **Primary goal**: What was the user trying to achieve?
- **Secondary goals**: Any related objectives discovered along the way
- **Errors encountered**: Mistakes, dead ends, wrong approaches
- **Successful path**: What actually worked

### 2. Abstract to Reusable Patterns

**Critical: Do NOT create skills for specific cases. Abstract to general patterns.**

Ask yourself:

- What CATEGORY of problem was solved? (not the specific instance)
- What would this look like with different data/context?
- Would this skill be useful in other projects?

**Abstraction levels (from bad to good):**

| Too specific (BAD)             | Good abstraction                     |
| ------------------------------ | ------------------------------------ |
| "Seed users from client Excel" | "Import spreadsheet data into Rails" |
| "Parse names into fields"      | (implementation detail, not a skill) |
| "Fix pytest in project X"      | "Configure pytest for monorepos"     |
| "Add dark mode to app Y"       | "Implement theme switching in React" |

**Rules:**

- Remove project names, organization names, specific entities
- Focus on the TECHNIQUE, not the specific data
- If something is just an implementation detail (name parsing, date formatting), it's not a separate skill
- One dialog = usually one skill (the main workflow), not multiple micro-skills

### 3. Extract Context-Specific Details

Depending on the task type, look for:

**Development tasks:**

- Commands and flags that worked
- Versions and compatibility (what works with what)
- Configuration that was needed
- Code patterns and architectural decisions
- Debugging process (how the root cause was found)
- Tool/library choices and why

**Research/analysis tasks:**

- Sources that proved useful
- Search strategies that worked
- How to validate findings

**Process/workflow tasks:**

- Order of operations (what must come first)
- Decision criteria (how choices were made)
- Stakeholders or dependencies

**Any task:**

- Prerequisites that weren't obvious
- Context that matters for success
- Signs that indicate the right/wrong path

### 4. Choose Topic (if multiple found)

If dialog contains several distinct learnable patterns, use AskUserQuestion:

**Question**: "I found several skill candidates. Which to create?"

**Options**: List 2-4 abstracted topics (not specific tasks), plus "All of them"

### 5. Validate Skill Candidate

Before proposing, check:

- [ ] Is this reusable in other projects/contexts?
- [ ] Is this a workflow/technique, not just a one-off fix?
- [ ] Would future-me benefit from having this skill?
- [ ] Is it abstracted enough to apply broadly?

If NO to any — either abstract further or skip skill creation.

### 6. Propose Topic (if valid)

Present ONE main skill (not a list of micro-topics):

```
Skill candidate: [Abstracted name]

What it captures: [1-2 sentences about the reusable pattern]

Key learnings:
- [Main insight 1]
- [Main insight 2]
- [Mistake to avoid]
```

Then ask using AskUserQuestion tool:

**Question**: "How does this skill proposal look?"

**Options**:

1. "Good, create it" — proceed to step 7
2. "Too specific" — re-abstract: remove project/entity names, find broader pattern
3. "Wrong focus" — re-analyze: what was the MAIN technique vs implementation details?
4. "Not reusable" — reconsider: is this a one-off task or a recurring pattern?

### 7. Revise (if needed)

Based on user's choice, fix the specific issue:

**"Too specific"**:

- What broader category does this belong to?
- Would this apply with different tools/platforms? Generalize.

**"Wrong focus"**:

- What would you google to solve this problem?
- The answer is probably the real skill name.

**"Not reusable"**:

- How often would this exact situation repeat?
- If rarely — maybe no skill needed. Ask user what they hoped to capture.

### 8. Prepare Knowledge Package

**Goal**: One sentence — what this skill helps achieve

**Trigger**: When should this skill activate? (keywords, file types, contexts)

**Mistakes to avoid**:

- Specific errors from the dialog
- Why they were wrong
- What they cost (time, confusion)

**Optimal path**:

- Shortest working sequence
- No exploration, only essentials
- Include specific commands/configs if applicable

**Key details**:

- Versions/compatibility if relevant
- Non-obvious prerequisites
- How to verify success

### 9. Create Skill

Use `/skill-creator` with the prepared knowledge package.
