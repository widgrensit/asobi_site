# ADR 0001: Samples gallery and the self-contained sample contract

Date: 2026-07-07

## Status

Proposed.

## Context

The onboarding upgrade's goal is that a first-time visitor feels it is easy to
spin up a game in minutes. The two-door docs (ADR-less, asobi_site#79),
`asobi init --template <engine>` (asobi-cli#31) and `asobi dev` (asobi-cli#32)
have shipped. Issue asobi_site#80 tracks a samples gallery: a place where a
visitor sees a real game and is one obvious action from running it.

Two constraints are fixed:

- **No free environments** (product decision, consistent with paid-only v2
  pricing). The asobi-saas-architecture-guardian redirected a one-click "provision
  a hosted demo env" button and approved only the lighter path: a gallery that
  points at `asobi init --template` + `asobi deploy` into the visitor's own
  authenticated, paid environment.
- **One source of truth.** `asobi init --template` already fetches the demo repos
  pinned by release tag; the gallery must not fork a second set of samples.

There is a real gap today: the demo repos are client-only and arena-specific.
`asobi init --template godot` yields a Godot *client* that needs the
`asobi_arena_lua` backend on :8085; it does not pair with `asobi dev` (which runs
a generic `lua/` game on :8084). So the clean "two commands to a running game"
story is not yet true - the honest recipe is three steps across two repos.

## Decision

1. **Sample contract: a sample is self-contained.** Each sample repo carries both
   the client and its server `lua/`, wired to the same local port, so the
   universal recipe is:

   ```
   asobi init mygame --template <engine>
   asobi dev
   # open the client in <engine>
   ```

   Fold the arena server Lua into each demo repo and align the port with
   `asobi dev`. This also fixes the `init --template` -> `asobi dev` pairing the
   tickets promised, so it is worth doing independent of the gallery.

2. **The gallery is data-driven on asobi_site.** A list of sample metadata
   (engine, genre, concept tags, media, blurb, template key) rendered as
   filterable cards (erlydtl view + Datastar filters by engine / genre / concept).
   Samples are the tag-pinned demo repos - the same source `asobi init --template`
   uses. Adding a sample is one demo repo plus one data entry.

3. **CTAs are honest.** Primary action per card is **Run it locally** (the free
   self-host path: the two commands). Secondary is **Deploy to cloud** ->
   `/docs/cloud` (paid). There is no one-click hosted-deploy button, because that
   would imply a free environment.

4. **The visible payoff without a per-visitor env** comes in tiers, all zero
   marginal cost: an autoplay muted clip/GIF per card (the `/demo` pattern); and
   one live, in-browser playable JS demo connecting to a single shared showcase
   backend asobi runs - a fixed-cost asset it controls, not a provisioned env.

## Consequences

- Enables the true two-command story and fixes `init --template` -> `asobi dev`
  composition (value beyond the gallery).
- Costs: reworking the three demo repos to bundle their server Lua and align
  ports, with an end-to-end verification per sample; building the data-driven
  page; and standing up plus serving one shared showcase backend with an
  embeddable JS client (CSP / iframe work).
- Forecloses per-visitor hosted demos - deliberately, per no-free-environments.
- Maintenance stays low: one pinned source, and the demos already auto-cut tags.

## Alternatives considered

- **Client-only demos with per-sample exact recipes** (three steps, two repos):
  rejected. The recipe differs per sample, contradicts the two-command promise,
  and reads as janky.
- **One-click hosted-deploy button:** rejected/redirected by the saas guardian -
  free public provisioning breaks paid-only and is a cost/abuse vector.
- **A wall of repo links** with no metadata, filters, or media: rejected - it
  rots, teaches nothing, and delivers no wow.

## Sequencing

1. Make samples self-contained and verify each runs via `init --template` +
   `asobi dev`.
2. Build the data-driven gallery page: cards, filters, the two-command CTAs.
3. Add the one live JS playable as the centerpiece.

Quality over quantity: three rock-solid, verified samples beat twelve that do not
run.
