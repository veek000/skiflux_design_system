# AGENTS.md

## Package usage policy
When implementing a feature, if a well-maintained package exists that would improve
performance, reliability, or correctness — and either doesn't affect the existing UI
or can be styled/adjusted to match it exactly — surface it as a suggestion with a
brief tradeoff summary (what it replaces, any new dependency risk, styling effort
needed) before implementing. Do not add or swap in a package without explicit
confirmation. Do not silently fall back to a hand-rolled/custom implementation
either, if a suitable package exists — ask first either way.
