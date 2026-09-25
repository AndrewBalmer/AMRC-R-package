# Legacy Provenance Scripts

> **These copies predate the corrected pneumococcal analysis. Do not use them
> as a source of results.**
>
> The canonical, corrected *S. pneumoniae* analysis lives in
> [AndrewBalmer/AMR-cartography](https://github.com/AndrewBalmer/AMR-cartography). Since these copies were taken
> (March 2026) it has had a PBP2B active-site motif fix, a corrected
> 170-marker panel (previously 157), and a full rerun of the mvLMM, uvLMM,
> epistasis and permutation-threshold analyses in
> `analysis/02-Genotype_to_phenotype_analyses/recomputed_170_workflow/`.
> Genotype-to-phenotype numbers produced by the notebooks here (15, 17–32)
> are therefore superseded, and the notebooks themselves have drifted from the
> upstream versions (for example 17 and 32).
>
> The phenotype and map analyses (01–16) are not affected: upstream changes to
> those notebooks were limited to path handling and a fixed random seed, and
> the map constants (326° rotation, dilation slopes 0.1842996 and 0.01814108)
> are unchanged.
>
> Compare any future genotype-to-phenotype port against the upstream
> `manuscript/Supplementary_File_1.csv` and `manuscript/source_data/`, not
> against these files.

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
