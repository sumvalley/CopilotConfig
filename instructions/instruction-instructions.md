# Instruction Writing Guide

Write instructions for the agent as operational rules, not human-oriented prose. Favor precision, structure, and explicit actions over broad guidance.

Based on Gábor Mészáros' guides on Medium

- [Claude.md Best Practices](https://cleverhoods.medium.com/claude-md-best-practices-7-formatting-rules-for-the-machine-a591afc3d9a9)
- [Do NOT Think of a Pink Elephant](https://cleverhoods.medium.com/do-not-think-of-a-pink-elephant-7d40a26cd072)
- [Instruction Best Practices: Precision Beats Clarity](https://cleverhoods.medium.com/instruction-best-practices-precision-beats-clarity-e1bcae806671)

## Core principles

1. **Lead with the desired action**
   - Start with what the agent should do.
   - Do not start with the forbidden behavior unless the instruction is a pure safety ban.

2. **Name exact constructs**
   - Prefer file paths, commands, imports, functions, flags, classes, and globs.
   - Avoid broad category words when a concrete construct exists.

3. **Keep scope exact**
   - Use specific paths, file patterns, or task contexts.
   - If the scope cannot be stated precisely, prefer an unconditional rule over a vague conditional one.

4. **Include brief rationale**
   - Add one short reason when it helps the agent generalize the rule.
   - Keep rationale concrete and tied to behavior.
   - Do not mention the banned construct in the rationale when a restriction will follow.

5. **Put hard bans last**
   - First say what to do.
   - Then say why.
   - Then say what not to do.

6. **Use structure the agent can scan**
   - Use headers, bullets, short sections, and backticks for commands and code constructs.
   - Do not bury rules in paragraphs.

7. **Make every instruction actionable**
   - The agent should be able to execute the instruction immediately without interpretation.
   - Replace vague phrases like "follow best practices" with specific required actions.

## Default instruction format

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

## Rules for each section

### Directive

- Must come first.
- Must name the exact preferred behavior.
- Must use concrete references when possible:
  - file paths like `src/payments/`
  - commands like `pytest`
  - imports like `unittest.mock`
  - APIs like `stripe.Customer.create()`
  - globs like `tests/integration/**/*.py`

### Why

- Keep to one sentence or one bullet.
- Explain the operational reason, not philosophy.
- Do not restate the directive in different words.
- Do not mention the prohibited construct if the instruction also has a restriction.
- Reinforce why the preferred behavior works, not why the banned behavior is bad.

### Restriction

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

## Scope rules

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

## Formatting rules

1. Use `##` headings for instruction blocks.
2. Use shallow hierarchy; avoid deep nesting.
3. Use bullets for rules.
4. Prefer one rule per bullet.
4. Put commands, paths, imports, functions, and filenames in backticks.
5. Keep paragraphs short or avoid them entirely.
6. Use descriptive filenames for instruction and support files the agent may discover.
7. Use conventional section names:
   - `## Testing`
   - `## Formatting`
   - `## Commands`
   - `## Structure`
   - `## Boundaries`
   - `## <Specific rule title>`

## Good examples

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

## Bad examples

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

## Rewrite checklist

Before saving an instruction, verify:

1. Does it start with the preferred action?
2. Does it name exact constructs instead of categories?
3. Is the scope exact, or should the instruction be unconditional?
4. Is there a short concrete reason?
5. Is the prohibition explicit and last?
6. Can the agent act on it immediately without guessing?

## Default template

Use this template for all new instructions:

```md
## <Title>

**Directive**
- Use `<exact preferred behavior>`.
- Apply this in `<exact scope>`.

**Why**
- `<short concrete reason>`.

**Restriction**
- Do not use `<exact banned construct>`.
```
