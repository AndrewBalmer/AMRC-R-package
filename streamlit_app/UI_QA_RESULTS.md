# Streamlit UI QA Results

## Pass date

- 4 April 2026

## Method

- live local Streamlit session at `http://127.0.0.1:8502`
- automated browser pass using Playwright on the running app
- direct visual inspection of captured screenshots

This was a browser-level QA pass, not just a backend or widget-contract check.

## Flows checked

### Bundled demo: MIC only

Verified:

- bundled demo button loads without upload
- run completes successfully
- phenotype map appears
- goodness-of-fit summaries appear
- report/download surface appears
- result bundle download control appears

Screenshot:

- `.tmp_browser_artifacts/02_mic_only_result.png`

### Bundled demo: MIC + numeric external features

Verified:

- bundled numeric demo loads without upload
- run completes successfully
- external map appears
- side-by-side map appears
- cluster scree diagnostics appear
- reference-distance relationship appears
- goodness-of-fit summaries appear
- report/download surface appears
- zipped output bundle control appears

Screenshot:

- `.tmp_browser_artifacts/03_numeric_external_result.png`

## Findings

- No blocking browser-level failures were found in the bundled demo flows.
- The previous result layout was too summary-JSON-heavy, pushing the actual map
  and report surfaces down the page.
- This was addressed by reorganizing the result view into tabs:
  - `Maps`
  - `Diagnostics`
  - `Tables`
  - `Reports`
  - `Raw summary`
- The reusable browser smoke script now exercises those tabbed flows directly:
  `streamlit_app/run_browser_qa.py`

## Remaining gaps

- This pass did not exhaustively test user-supplied uploads across all possible
  malformed external schemas.
- This pass did not exercise PDF export in-browser.
- This pass did not test advanced association workflows, which are still
  intentionally outside the current app surface.
