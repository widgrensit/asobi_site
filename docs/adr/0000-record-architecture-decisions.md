# ADR 0000: Record architecture decisions

Date: 2026-07-07

## Status

Accepted.

## Context

asobi_site carries product and onboarding decisions (docs structure, the
cloud-vs-self-host framing, what we do and do not offer) whose trade-offs are
not obvious from the code. Without a durable record we rediscover the same
arguments and sometimes reverse them on weaker grounds than the original choice.
The asobi and asobi_saas repos already keep ADRs; this brings asobi_site in line.

## Decision

Record significant decisions as numbered markdown files in `docs/adr/`, one file
per decision, `NNNN-short-slug.md`, using Michael Nygard's lightweight template:

- **Title** - `ADR NNNN: short imperative phrase`
- **Date** - `YYYY-MM-DD`
- **Status** - `Proposed` | `Accepted` | `Superseded by ADR NNNN` | `Deprecated`
- **Context** - what is true now that motivates the decision
- **Decision** - the choice, in one or two short paragraphs
- **Consequences** - what it enables, what it costs, what it forecloses
- **Alternatives considered** - options ruled out, with a one-line rationale

## Consequences

New contributors can read the ADR log to understand why the product is shaped as
it is. The cost is a short writeup per significant decision, which is cheap
relative to relitigating them.
