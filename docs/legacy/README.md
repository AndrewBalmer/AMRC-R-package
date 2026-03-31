# Legacy Provenance Scripts

This folder keeps manuscript-era scripts that are useful as provenance and
historical reference, but that are no longer the recommended user-facing entry
points for the package.

Current contents:

- `29-mvLMM-heritability-and-epistatic-mvLMM.py`

That Python script is the original manuscript-era mixed-model workflow. Its
generic reusable capabilities have been progressively re-exposed through the
package API and the bundled generic LIMIX helper script in `inst/python/`.

Keep this folder as a reference implementation, not as the primary analysis
interface for new users.
