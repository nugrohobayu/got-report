---
description: Rename this Flutter project's Dart package name and/or native application identifier
argument-hint: [new_project_name] [new_package_name]
---

Use the Skill tool with `skill: "rename-flutter-project"` to run the rename flow (see
[.claude/skills/rename-flutter-project/SKILL.md](../skills/rename-flutter-project/SKILL.md)).

`$ARGUMENTS` may contain up to two values: the first is the new Dart project name (pubspec `name:`,
`lowercase_with_underscores`), the second is the new package identifier (reverse-domain, e.g.
`com.example.app`). Pass whichever were given through to the skill via context so it doesn't need to
re-ask for them.

Whatever was not given must be asked for (see the skill's "Collect both values first" section). In
particular, if only the project name was given, always ask for the package identifier too, suggesting
`com.newtronic.<project_name>`. A part is left unchanged only when the user explicitly says so.

Before running the rename script, follow the skill's own safety instructions: show the detected old →
new mapping, remind the user this project has no git repository (so the change can't be undone with
`git checkout`), and get explicit confirmation to proceed.
