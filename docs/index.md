# Astram Documentation

This folder contains project documentation for Astram. The docs are intentionally concise and focused on the current codebase behavior.

## Contents

- whitepaper.md: system overview and protocol description
- architecture.md: component and data-flow design
- security.md: threat model and security considerations
- design.md: product and UX design principles

## Notes

- These documents describe the implementation in this repository, not a separate spec.
- Consensus sections reflect target-based PoW (`hash < target`) and damped rolling retargeting for ~120s blocks.
- If you need more detail (math, formal proofs, or protocol schemas), add a request and we will extend the docs.
