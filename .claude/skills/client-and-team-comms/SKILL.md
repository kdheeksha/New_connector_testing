---
name: client-and-team-comms
description: Draft client/Slack messages, DE-agent briefs, short change summaries and pasted-thread action lists in the user's working style. Use whenever the user says "draft a message/query", "short msg", "can u be specific", "explain this", or asks to enhance a prompt.
---

# Client & team communication

## Style the user keeps steering toward
- **Short.** "Client name and the change" = two lines. One idea per bullet.
- **Specific to the client**, not generic ("be specific about Equip Foods").
- **Plain English** for marketers/clients; explain the finding before the SQL. When user says "I did not understand",
  re-explain with a concrete example (Mon/Wed/Fri page visits) instead of more detail.
- **Recommend, then offer the alternative**: "Our thinking is X. Happy to go the other way — just let us know."
- **Commitment line** when appropriate: "Once confirmed we can have this implemented by end of this week."
- Keep the message faithful to the *spec*: if the draft recommends the opposite of what is being built, call it out and
  correct it, and tell the builder/stakeholder.

## Templates
**Client clarification (Slack):** greeting + what they asked → the nuance found in data → options (bold) → concrete example →
our recommendation → easy opt-out → timeline → thanks.

**DE-agent brief (markdown file):**
`# Title` · What we know (table) · Why it matters now · Numbered questions · **What we are not asking for** · Context.
Examples written: faire_rca_brief, faire_followup_brief, july_zero_value_brief, seeding_rule_brief, de_agent_verification_brief.
Follow-up briefs state which items were "raised but not closed" and exact checks (incremental vs full-refresh, per-month zero
counts, git history of the exclusion, snapshots/BI extracts, export dates).

**Change summary for stakeholders:** `<Client> — <change in one line>. Validated: row counts + key metrics match prod. Open: <decision>.`

## Extracting action items from pasted Slack/ClickUp
See `connector-migration-and-brd`. Never invent items; flag unclear names; ask for missing screenshots.

## Recall questions
When asked "how did we find out about X" (e.g. Faire customers), search the work folder briefs/SQL first, then answer with the
chain: symptom → profile query → RCA brief → finding. Cite file names.

## Escalation phrasing
State the blocker and the exact remedy: "needs `bigquery.jobs.listAll`", "needs Luzmo dataset-connections page",
"need the client customer list for other months".
