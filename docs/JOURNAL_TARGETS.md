# Possible Journal Targets

This shortlist is based on the current manuscript shape: an R package and
prototype app for multivariate AMR phenotype cartography, with package-backed
figures, validation, public examples, and a retained biological case study.

## Recommended Strategy

Best initial route:

1. Post a polished preprint to bioRxiv once the full manuscript PDF, figures,
   tables, supplementary information, and reference list are stable.
2. Submit to a journal that accepts software/methods manuscripts and values
   biological utility, not only software existence.
3. Keep `v0.2.0` as the manuscript software baseline unless the manuscript
   figures and text are deliberately moved to `v0.2.1`.

## Shortlist

### 1. PLOS Computational Biology, Software Article

Fit:

- Strong if the manuscript emphasizes biological utility, reproducibility, and
  a clear advance over notebook-based AMR phenotype analysis.
- Best if the figures show more than software plumbing: phenotype maps,
  genotype/structure comparison, cross-species examples, and retained
  pneumococcal biological continuity.

Pros:

- High visibility for open-source computational biology software.
- Software articles are an explicit article type.
- Good home if the story is framed as a reusable method for AMR phenotype
  landscapes.

Risks:

- The package needs a crisp statement of need and strong biological examples.
- The public cross-species examples are tiny, so the pneumococcal and/or
  *S. suis* case-study evidence needs to carry the biological relevance.

Preparation notes:

- Tighten the introduction around the gap left by AMR and AMRgen.
- Make Figure 1 a strong workflow/architecture figure.
- Make Figure 2 or 4 the biological payoff figure.

Source checked:

- PLOS Computational Biology states that it publishes Research, Methods, and
  Software articles and that software articles should describe open-source
  tools of broad utility.

### 2. BMC Bioinformatics, Software Article

Fit:

- Very plausible for an R package with reusable methods, validation, example
  data, and app/reporting support.

Pros:

- Explicit Software Article format.
- Scope includes computational tools for biological data analysis.
- More forgiving than PLOS Computational Biology if the manuscript is framed
  as practical infrastructure rather than a major conceptual advance.

Risks:

- Reviewers may ask for clearer benchmarking, broader examples, or stronger
  comparison with existing tools.
- The app should be described as prototype/supporting interface, not over-sold.

Preparation notes:

- Keep Methods/Implementation detailed.
- Include strong supplementary validation and reproducibility notes.
- Add a software availability and requirements table.

Source checked:

- BMC Bioinformatics describes Software Articles and considers novel
  computational algorithms, software, models, and tools for biological data.

### 3. Microbial Genomics

Fit:

- Good if the manuscript leans into microbial genomics, AMR surveillance, and
  genotype/phenotype comparison.

Pros:

- Audience is directly relevant to AMR genomics and pathogen surveillance.
- Open data and reproducible code expectations align with the repository.

Risks:

- A software-only paper may need stronger microbial genomics application than
  the current tiny public examples.
- The retained *S. pneumoniae* case study likely needs to be foregrounded more.

Preparation notes:

- Expand the biological results around *S. pneumoniae* and *S. suis*.
- Use public examples as portability checks, not as biological evidence.
- Prepare data summary and author statement sections carefully.

Source checked:

- Microbial Genomics describes scope across genomic methodologies,
  populations, pathogens, epidemiology, and open data.

### 4. Bioinformatics, Application Note

Fit:

- Possible, but only if the paper is compressed heavily.

Pros:

- High visibility for bioinformatics software.
- Application Notes are specifically for novel software, databases, web
  services, and interfaces.

Risks:

- Application Notes are short. The current manuscript has too much context,
  validation, and case-study detail for an easy fit.
- The paper may need to be reduced to approximately one main figure plus
  supplementary material.

Preparation notes:

- Use a very concise Statement of Need.
- Move most validation, examples, and app detail to supplement.
- Consider this only if a short, high-impact software note is preferred over a
  fuller methods paper.

Source checked:

- Bioinformatics Application Notes are short descriptions of novel software,
  databases, web services, and interfaces.

### 5. Journal of Open Source Software

Fit:

- Good fallback or parallel option if the goal is a citable, peer-reviewed
  software record rather than a full AMR methods manuscript.

Pros:

- Diamond open access: free to read and free to publish.
- Review happens openly on GitHub and focuses directly on software quality,
  documentation, tests, and statement of need.

Risks:

- JOSS papers are short and will not carry the biological narrative.
- It is less ideal if the goal is a microbiology/AMR audience.

Preparation notes:

- Prepare a separate short `paper.md` with Statement of Need, Summary,
  References, and software citations.
- Keep the full AMR manuscript for bioRxiv or a biological methods journal.

Source checked:

- JOSS describes itself as a developer-friendly, peer-reviewed, open-access
  journal for research software packages, with open GitHub-based review.

### 6. SoftwareX

Fit:

- Reasonable if the goal is a software-description paper with broad reuse
  framing.

Pros:

- Explicitly recognizes research software.
- Less demanding than a domain-specific biological methods journal.

Risks:

- Audience is broad and less AMR-specific.
- Biological framing may be diluted.

Preparation notes:

- Use the current manuscript as the basis for a 3000-word software article.
- Make reuse, validation, and reproducibility the main claims.

Source checked:

- SoftwareX states that it aims to acknowledge the impact of software on
  research practice and encourages significant reuse within and beyond the
  original domain.

## Current Best Recommendation

Primary target:

- BMC Bioinformatics if we want the most practical route for a full software
  manuscript.

Ambitious target:

- PLOS Computational Biology Software Article if we strengthen the biological
  payoff figures and explicitly position the tool relative to AMRgen and AMR.

Domain-specific target:

- Microbial Genomics if we expand the case-study biology and reduce the
  software-infrastructure feel.

Software-citation target:

- JOSS if we want a fast, focused, citable software paper, separate from the
  fuller AMR manuscript.

## What The Manuscript Needs Before Submission

- Final author list and affiliations.
- Final funding and acknowledgements.
- Verified reference list.
- Zenodo DOI or similar archive for the chosen software release.
- Final decision on whether figures use `v0.2.0` or `v0.2.1`.
- A stronger Figure 1 schematic if submitting to PLOS Computational Biology or
  Microbial Genomics.
- A more biological Figure 4 result panel if submitting to Microbial Genomics.
- Supplementary PDF assembled from
  [SUPPLEMENTARY_INFORMATION.md](/Users/ab69/AMRC-R-package/docs/SUPPLEMENTARY_INFORMATION.md).
