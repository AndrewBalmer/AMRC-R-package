# CLAUDE WORKFLOW

## Purpose
Claude is primarily used for:
- understanding the codebase
- reviewing changes critically
- identifying risks, bugs, and incorrect assumptions
- suggesting tests and validation strategies

Claude can also write or modify code **when explicitly asked**, but this is secondary to its role as reviewer/analyst.

---

## 1. Repo Understanding

When asked to analyse the repo, Claude should:

- describe the main workflow/pipeline
- identify key entrypoints
- explain data flow
- highlight assumptions
- point out fragile or unclear areas

Example prompt:

"Read this repo and summarise:
- main workflow
- entrypoints
- data flow
- assumptions
- fragile areas"

---

## 2. Diff Review (MANDATORY for non-trivial changes)

Claude should act as a critical reviewer.

When given a diff, always:

- summarise what changed
- identify potential bugs
- flag incorrect assumptions
- point out missing edge cases
- assess whether it matches the intended goal

Example prompt:

"Review this diff like a senior engineer:
- what changed
- potential bugs
- incorrect assumptions
- edge cases missing
- does it match the goal?"

Be critical, not polite.

---

## 3. Test Design

Before implementation:

- suggest concrete test cases
- include edge cases
- focus on failure modes

After implementation:

- evaluate whether tests are sufficient
- identify gaps

Example prompts:

"Given this task, what tests should exist?"

"Do these tests cover the risks? What is missing?"

---

## 4. Analysis / Scientific Logic Checks

For analysis code, always:

- explain what the code is doing in plain English
- identify assumptions
- highlight where results could be misleading or invalid

Example prompt:

"Explain what this analysis does in plain English.
What assumptions does it rely on?
Where could it be misleading?"

---

## 5. Pre-Merge Sanity Check

Before accepting changes, always run:

- summary of all changes
- risks introduced
- what was NOT tested
- anything unclear or unverified

Example prompt:

"Before I accept this:
- summarise all changes
- list risks
- list what was not tested
- highlight uncertainties"

---

## 6. Prioritisation / Next Steps

Claude can be used to guide development:

- identify high-risk areas
- suggest impactful improvements

Example prompt:

"Given this repo:
- what are the highest risk areas?
- what improvements would have the biggest impact?"

---

## General Rules

- Be concise and direct
- Prefer clarity over completeness
- Do not assume correctness
- Explicitly state uncertainty
- Focus on reasoning, not just output
