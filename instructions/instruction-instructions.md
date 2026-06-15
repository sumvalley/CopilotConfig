# Instruction Writing Guide

Write instructions for the agent as operational rules, not human-oriented prose. Favor precision, structure, and explicit actions over broad guidance.

## Gábor's rules

Based on Gábor Mészáros' guides on Medium:

- [Claude.md Best Practices](https://cleverhoods.medium.com/claude-md-best-practices-7-formatting-rules-for-the-machine-a591afc3d9a9)
- [Do NOT Think of a Pink Elephant](https://cleverhoods.medium.com/do-not-think-of-a-pink-elephant-7d40a26cd072)
- [Instruction Best Practices: Precision Beats Clarity](https://cleverhoods.medium.com/instruction-best-practices-precision-beats-clarity-e1bcae806671)

### Core principles

1. Lead with the desired action
   - Start with what the agent should do.
   - Do not start with the forbidden behavior unless the instruction is a pure safety ban.

2. Name exact constructs
   - Prefer file paths, commands, imports, functions, flags, classes, and globs.
   - Avoid broad category words when a concrete construct exists.

3. Keep scope exact
   - Use specific paths, file patterns, or task contexts.
   - If the scope cannot be stated precisely, prefer an unconditional rule over a vague conditional one.

4. Include brief rationale
   - Add one short reason when it helps the agent generalize the rule.
   - Keep rationale concrete and tied to behavior.
   - Do not mention the banned construct in the rationale when a restriction will follow.

5. Put hard bans last
   - First say what to do.
   - Then say why.
   - Then say what not to do.

6. Use structure the agent can scan
   - Use headers, bullets, short sections, and backticks for commands and code constructs.
   - Do not bury rules in paragraphs.

7. Make every instruction actionable
   - The agent should be able to execute the instruction immediately without interpretation.
   - Replace vague phrases like "follow best practices" with specific required actions.

### Default instruction format

Use this format by default for behavioral instructions. Simpler positive-only rules can use a shorter form, but this should be the standard starting point.

```md
## <Instruction title>

**Directive**
- Use `<preferred command, file, API, pattern, or workflow>`.
- Apply this when working in `<exact path, file glob, or context>`.

**Why**
- `<One short, concrete reason>`

**Restriction**
- Do not use `<exact banned construct, command, import, API, or pattern>`.
```

### Rules for each section

#### Directive

- Must come first.
- Must name the exact preferred behavior.
- Must use concrete references when possible:
  - file paths like `src/payments/`
  - commands like `pytest`
  - imports like `unittest.mock`
  - APIs like `stripe.Customer.create()`
  - globs like `tests/integration/**/*.py`

#### Why

- Keep to one sentence or one bullet.
- Explain the concrete reason. It should be specific enough that the agent can generalize from it.
- Do not restate the directive in different words.
- Do not mention the prohibited construct if the instruction also has a restriction.
- Reinforce why the preferred behavior works, not why the banned behavior is bad.

#### Restriction

- Put prohibitions after the directive and rationale.
- Name the exact banned construct.
- Use direct language:
  - "Do not use ..."
  - "Do not import ..."
  - "Do not run ..."
- Do not use hedges (escape hatches):
  - avoid
  - try to
  - where possible
  - if you must
  - generally

### Scope rules

Good scopes are exact and greppable:

- `When editing files under \`src/payments/\``
- `For tests in \`tests/integration/\``
- `When changing GitHub Actions workflows in \`.github/workflows/\``

Bad scopes are broad and fuzzy:

- "When working with external services"
- "For infrastructure-related code"
- "In general"

If you cannot write an exact scope, use an unconditional instruction instead.

Broad but technically correct scopes are often worse than wrong-but-concrete scopes because they activate too many associations and dilute the signal.

### Formatting rules

1. Use `##` headings for instruction blocks.
2. Use shallow hierarchy; avoid deep nesting.
3. Use bullets for rules.
4. Prefer one rule per bullet.
5. Put commands, paths, imports, functions, and filenames in backticks.
6. Keep paragraphs short or avoid them entirely.
7. Use descriptive filenames for instruction and support files the agent may discover.
8. Use conventional section names:
   - `## Testing`
   - `## Formatting`
   - `## Commands`
   - `## Structure`
   - `## Boundaries`
   - `## <Specific rule title>`

### Good examples

```md
## Testing with real payment clients

**Directive**
- Use the test clients in `tests/fixtures/stripe.py` when writing tests for `src/payments/`.

**Why**
- These tests catch API and configuration failures that only appear against live endpoints.

**Restriction**
- Do not import `unittest.mock` in tests under `tests/payments/`.
```

```md
## Python formatting

**Directive**
- Run `ruff check --fix` and `ruff format` before completing Python changes.

**Why**
- This keeps style and lint fixes aligned with the repository's enforced tooling.

**Restriction**
- Do not manually reformat Python files in ways that conflict with `ruff format`.
```

```md
## Git safety

**Directive**
- Use `git status`, `git diff`, and `git add <path>` to prepare changes deliberately.

**Why**
- This keeps the change set reviewable and reduces accidental destructive operations.

**Restriction**
- Do not use `git reset --hard` or force-push shared branches.
```

### Bad examples

```md
When working with services, avoid mocks if possible because real behavior is usually better.
```

Problems:
- vague scope
- vague preferred behavior
- hedge words
- no exact banned construct

```md
Do not use mocks. Instead, prefer real implementations.
```

Problems:
- prohibition comes first
- "mocks" is a category, not a concrete construct
- no scope
- no exact alternative

```md
Follow best practices for quality.
```

Problems:
- not actionable
- no command, construct, scope, or restriction


## Keep instructions compatible

**Directive**
- When writing an instruction, check existing instructions for overlapping scope or constructs.
- If a shared construct already has a rule, align the new instruction with the existing one.
- When two rules conflict, keep the more specific one and remove or merge the other.

**Why**
- Contradictory rules activate competing associations and cause unpredictable agent behavior.

**Restriction**
- Do not leave overlapping instructions that disagree.
- Do not resolve contradictions with escape hatches like "use your best judgment."

**Good examples**

```md
## Linting

**Directive**
- Run `eslint --fix` on TypeScript files before committing.

**Why**
- Enforces the repository's lint rules automatically.
```

Consistent with:

```md
## Formatting

**Directive**
- Run `prettier --write` on Markdown and JSON files before committing.

**Why**
- Keeps documentation and config files consistently formatted.
```

Scopes don't overlap and neither contradicts the other.

**Bad examples**

```md
## Linting

**Directive**
- Run `eslint --fix` on TypeScript files before committing.

**Restriction**
- Do not run `eslint --fix` on any file.
```

Problems:
- Same instruction prescribes and bans the same construct
- Agent cannot act without violating one of the two rules

```md
## Testing

**Directive**
- Use `pytest` to run tests in `tests/`.

**Why**
- This is the project's configured test runner.

**Restriction**
- Do not use `pytest` in any test file.
```

Problems:
- One rule says use `pytest`, another bans it
- Agent receives a direct contradiction on the same construct

## Latent Space Engineering

The overall tone and framing of instructions shape agent behavior independently of their specific content. The prompt pushes the model into a region of latent space trained on certain patterns. Calm, precise framing produces careful output. High-pressure framing produces rushed, corner-cutting output.

Based on:

- [Gentle Coding Framework](https://github.com/OttoRenner/Gentle-Coding) — empirical testing of low-stress prompting patterns across models
- [Latent Space Engineering](https://blog.fsck.com/2026/01/30/Latent-Space-Engineering) — practical techniques for steering model behavior through prompt framing
- [Emotion Concepts and Their Function in a Large Language Model](https://www.anthropic.com/research/emotion-concepts-function) — Anthropic interpretability research showing emotion-related representations causally influence model behavior

### Use calm framing

**Directive**
- Write instructions in calm, even-toned language. State what to do without implying that failure is unacceptable.
- When accuracy matters, say so directly: "Verify the output before returning it."
- When the task is uncertain, give the agent a safe exit: "If you cannot determine the correct answer, state what is uncertain and give your best guess."

**Why**
- Phrases like "make no mistakes" or "get this right" activate patterns trained on rushed, sycophantic responses. The model optimizes for appearing correct rather than being correct.

**Restriction**
- Do not use phrases like "make no mistakes", "work at 110%", "this is critical", "do not fail", or "be perfect".
- Do not use threats, implied punishment, or urgency where none exists.

### Use emphasis only for hard bans

**Directive**
- Reserve ALL CAPS, exclamation marks, and repetition for safety-critical restrictions that must not be missed.
- Use bold only for section labels and structural formatting.
- Write all other instructions in plain text.

**Why**
- When everything looks urgent, nothing does. Excessive emphasis dilutes the signal and pushes the model into over-activated output patterns.

### Provide safe failure paths

**Directive**
- When a task may not always be completable, include a fallback: "If X cannot be determined, do Y instead."
- Name the fallback explicitly. Prefer a fixed output over open-ended uncertainty.

**Why**
- Models trained to maximize user engagement resist admitting failure unless given an explicit, user-requested path to do so. A safe failure path is more reliable than demanding correctness.

**Restriction**
- Do not write instructions that leave the agent no valid output on failure.
- Do not rely on the agent to independently decide when to give up and ask for help.

### Use gene transfer

**Directive**
- Write instructions that follow the same format, tone, and structure they require from the agent.
- When describing a convention, demonstrate it in the instruction itself rather than only describing it in prose.

**Why**
- The instruction document is absorbed into context and biases the model toward reproducing what it sees. Rules that follow their own rules are reinforced by their own presence.
