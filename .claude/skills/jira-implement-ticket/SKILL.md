---
name: jira-implement-ticket
description: Connect to Jira via the Atlassian Rovo MCP tools, fetch a ticket, and implement the requested change in this Flutter project (myapp). Trigger on requests like "implement tiket jira", "kerjain PROJ-123", "implement PROJ-123", "code this ticket", "kerjakan ticket ini", "buat sesuai tiket jira", "connect jira and implement the ticket". This skill only covers connecting, reading the ticket, and writing the code for it — it does NOT build, deploy, or transition the ticket past an optional "In Progress" move.
---

# Jira Implement Ticket

Connects to Jira through the Atlassian Rovo MCP tools, reads a ticket, and implements it in this codebase
following the architecture documented in [README.md](../../../README.md). This skill stops once the code
change is implemented and analyzed — it deliberately does not build/deploy/transition the ticket past
"In Progress", since later status changes should only happen after the user has reviewed the actual change.

Uses the **Atlassian Rovo MCP tools** exclusively — never call the Jira REST API directly (no raw
`fetch`/`curl` against `atlassian.net`). These tools are **deferred**: their schemas aren't loaded by
default. Before calling any of them for the first time in a run, use `ToolSearch` with
`select:mcp__claude_ai_Atlassian_Rovo__<name>` (comma-separate multiple names) to load their schemas.

## Step 0 — connect: resolve the Atlassian site

Call `getAccessibleAtlassianResources` to get the `cloudId` for this session (needed by every other call
below). Do this once per run, even if a ticket key was already given as a command argument — the
connection itself needs verifying, not just the ticket key.

- If the call errors (MCP server not reachable, auth/session failure) or returns no accessible sites: tell
  the user plainly that the Atlassian Rovo connection isn't working, and that they should check the MCP
  connection (e.g. via `/mcp` or their Claude Code integrations settings) rather than retrying blindly.
  Stop here.
- If it returns more than one site and it's not obvious which one this project's tickets live in, ask the
  user which site/cloudId to use instead of guessing.

## Step 1 — get the ticket key

If a ticket key wasn't already given (e.g. as a command argument), ask the user for it directly (or via
`AskUserQuestion`): **"Kunci tiket Jira yang mau dikerjakan?"** (e.g. `PROJ-123`).

- If it's empty or clearly not a Jira key (no `PROJECT-123` shape), ask again — do not guess a key or
  search for "the most likely ticket." This project isn't tied to one specific Jira project key, so don't
  assume a prefix.
- Do not proceed past this point without a real ticket key.

## Step 2 — fetch and validate the ticket

Call `getJiraIssue` with the `cloudId` and ticket key. If this fails or the ticket doesn't exist:

- Report the failure in plain terms (invalid key vs. not found vs. no permission, based on the error).
- Ask again for the correct key — do not proceed on an unconfirmed ticket.

Also check for extra context beyond the description that could change the implementation:

- `getJiraIssueRemoteIssueLinks` — linked designs (e.g. a Figma file), specs, or related tickets.
- Any images/attachments referenced in the description — if a design mockup is linked and Figma MCP tools
  are available, it's reasonable to pull it for detail, but don't block on this if it's not there.

## Step 3 — understand the requirement before touching code

From the ticket's summary, description, and any acceptance criteria, work out concretely what
behavior/screen/flow is being added, changed, or fixed, and map it onto this project's actual structure
(feature-first clean architecture — see [README.md](../../../README.md)):

- A new feature or screen → a new `lib/features/<feature>/{data,domain,presentation}/` slice, mirroring
  the existing `posts` feature (model → datasource → repository impl on the data side; entity → repository
  interface → usecase on the domain side; bloc/event/state → page → widgets on the presentation side).
- A change to an existing feature → follow that feature's existing layer split; don't collapse layers or
  bypass the domain layer to save time.
- A new network call → a method on the relevant `RemoteDataSource`, calling through `ApiClient`
  ([lib/core/network/api_client.dart](../../../lib/core/network/api_client.dart)), which wraps `package:dio`
  — **note:** the README describes this as `package:http`, but the code actually uses `dio`; trust the code,
  not the README, on this point.
- A new download/file-fetch → `DownloadService`
  ([lib/core/network/download_service.dart](../../../lib/core/network/download_service.dart)), not a new
  ad-hoc `Dio`/`http` call.
- A new route → `AppRouter` ([lib/core/router/app_router.dart](../../../lib/core/router/app_router.dart))
  (`go_router`).
- A new dependency to inject → wire it through `MultiRepositoryProvider`/`BlocProvider` in
  [lib/main.dart](../../../lib/main.dart) — this project deliberately does **not** use `get_it` or any
  service locator.
- A reusable UI piece → check [lib/core/widgets/](../../../lib/core/widgets/) first (`AppButton`,
  `AppTextFormField`, `AppImageView`, `AppLoadingView`, `AppEmptyView`, `ErrorView`) before writing a new
  one-off widget.
- Errors that need surfacing to the UI → a data-layer `Exception`
  ([lib/core/error/exceptions.dart](../../../lib/core/error/exceptions.dart)) mapped to a domain/presentation
  `Failure` ([lib/core/error/failures.dart](../../../lib/core/error/failures.dart)) by the repository impl,
  not a raw exception leaking into the bloc/UI.

**If the ticket is ambiguous, missing key details (exact copy, which screen it applies to, expected
behavior on error, etc.), or conflicts with the existing architecture** — ask the user rather than guessing
or inventing requirements. Silently filling gaps with assumptions on a real ticket produces code that
doesn't match what was actually asked for.

## Step 4 — plan before large changes

For anything beyond a small, obvious fix, propose a short implementation plan (files to touch, the
approach) and get the user's go-ahead before editing — use plan mode if available. For a small,
unambiguous change (e.g. a copy fix, a one-line constant), it's fine to just implement it directly.

## Step 5 — implement

Follow this repo's existing conventions (see [README.md](../../../README.md) and the surrounding code) —
don't introduce new state-management patterns, new persistence helpers, or new networking helpers when the
existing ones already cover the case. Keep the change scoped to what the ticket asks for; don't bundle in
unrelated refactors.

After implementing, run:

```bash
fvm flutter analyze
```

(this project pins its Flutter version via FVM — see [.fvmrc](../../../.fvmrc) — so prefix `flutter`/`dart`
commands with `fvm` per the README). Fix any new warnings/errors it reports. If `fvm`/`flutter` isn't
available in the current shell, say so explicitly rather than silently skipping this step or claiming the
change was verified. There is no CI wired up here, so static analysis (plus `fvm flutter test` if relevant
tests exist) is the main automated check available — don't claim the change is "tested" beyond that. If the
change is UI-visible, mention it should be run and eyeballed on a device/emulator (`fvm flutter run`) before
this is considered done.

## Step 6 — optional: mark the ticket "In Progress"

Jira ticket transitions are visible to other people on the team, so ask before changing ticket state (this
is different from just reading it). Ask the user: **"Mau saya pindahin tiket ke status In Progress
sekarang?"**

- If yes: call `getTransitionsForJiraIssue`, look for a transition whose target status name matches
  "In Progress" (or an equivalent in-progress-like status), and call `transitionJiraIssue` with the
  resolved transition ID. Never hard-code a transition ID — resolve it live, since IDs/status names differ
  per project. If no matching transition exists, report the available transitions and don't force one.
- If no, or the user doesn't answer either way, just skip this step — it's optional and not required to
  finish the skill.

## Step 7 — report back

Summarize for the user:

- Ticket key and title, and a one-line restatement of what was implemented.
- Files changed.
- Result of `fvm flutter analyze` (clean, ran with issues, or couldn't run — and why).
- Anything you asked about / assumed, called out explicitly.
- A reminder that build/deploy/further status transitions are separate steps, once the user has reviewed
  this change.

## Error handling summary

| Situation                                                    | Behavior                                                                             |
|---------------------------------------------------------------|---------------------------------------------------------------------------------------|
| Atlassian Rovo MCP unreachable / no accessible site           | Report the connection failure plainly, point at the MCP connection, stop              |
| Multiple accessible sites, ambiguous which to use              | Ask the user which site/cloudId, don't guess                                          |
| No ticket key given                                            | Ask again; never guess or proceed without one                                         |
| Ticket key invalid / ticket not found                          | Report clearly, ask again for the correct key                                         |
| Ticket requirements ambiguous or missing detail                 | Ask the user for clarification; don't invent requirements                             |
| Requested change conflicts with existing architecture/patterns | Flag the conflict and ask how to proceed instead of silently picking a new pattern     |
| `fvm flutter analyze` reports new issues after the change       | Fix them before reporting done, or explain clearly why they're pre-existing/unrelated  |
| `fvm`/`flutter` not available in the current shell              | Say so explicitly instead of skipping verification silently                           |
