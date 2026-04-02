# README_AI

This is a short agent-facing orientation note for work in this repository.

## Default Expectation

Before trusting a change, run validation appropriate to the size and risk of
the change.

Primary references:

- [CLAUDE_WORKFLOW.md](/Users/ab69/AMRC-R-package/CLAUDE_WORKFLOW.md)
- [AGENT_VALIDATION_WORKFLOW.md](/Users/ab69/AMRC-R-package/AGENT_VALIDATION_WORKFLOW.md)
- [VALIDATION.md](/Users/ab69/AMRC-R-package/VALIDATION.md)
- [VALIDATION_CHECKLIST.md](/Users/ab69/AMRC-R-package/VALIDATION_CHECKLIST.md)

## Validation Commands

Fast staged validation:

```bash
Rscript tools/run_validation.R --stage smoke
Rscript tools/run_validation.R --stage ci
Rscript tools/run_validation.R --stage release
```

Additional repo commands:

```bash
Rscript -e 'testthat::test_local(".")'
Rscript tools/check_readme_examples.R
Rscript tools/render_vignettes.R
R CMD build --no-build-vignettes .
R CMD check --no-manual --ignore-vignettes amrcartography_*.tar.gz
```

## Agent Rules

- Inspect current validation coverage before adding new code.
- Do not assume existing tests are sufficient.
- Update validation docs/tests/manifests when workflows change.
- Prefer stable schema/count/metric checks over brittle file-equality checks
  when appropriate.
- Document assumptions explicitly.
- Treat Linux CI as the authoritative gate when local OpenMP/shared-memory
  behaviour is unreliable.
