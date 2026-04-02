# Legacy Provenance Scripts

This folder keeps manuscript-era scripts that are useful as provenance and
historical reference, but that are no longer the recommended user-facing entry
points for the package.

Current contents:

- `29-mvLMM-heritability-and-epistatic-mvLMM.py`
- `02-Genotype_to_phenotype_analyses/`

That Python script is the original manuscript-era mixed-model workflow. Its
generic reusable capabilities have been progressively re-exposed through the
package API and the bundled generic LIMIX helper script in `inst/python/`.

The archived `02-Genotype_to_phenotype_analyses/` folder contains the later
genotype-to-phenotype manuscript notebooks that informed the generic helper and
plotting layers now exposed through the package. It is retained as provenance,
not as the supported analysis interface.

Keep this folder as a reference implementation, not as the primary analysis
interface for new users.
