---
description: Connect to Jira and implement a ticket in this Flutter project
argument-hint: [PROJ-123]
---

Use the Skill tool with `skill: "jira-implement-ticket"` to run the connect + ticket-implementation flow
(see [.claude/skills/jira-implement-ticket/SKILL.md](../skills/jira-implement-ticket/SKILL.md)).

If a Jira ticket key was given as an argument (`$ARGUMENTS`), pass it via the Skill tool's `args` so the
skill doesn't need to re-ask for it in its Step 1 — it still needs to run its Step 0 (resolving the
Atlassian site/cloudId) regardless of whether a key was given.
