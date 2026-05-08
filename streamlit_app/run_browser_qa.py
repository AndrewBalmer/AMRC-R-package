from __future__ import annotations

import argparse
import asyncio
from pathlib import Path


async def wait_for_completion(page, needle: str, timeout_seconds: int = 120) -> str:
    for _ in range(timeout_seconds):
        text = await page.locator("body").inner_text()
        if needle in text and "Running R backend..." not in text:
            return text
        await page.wait_for_timeout(1000)
    raise RuntimeError(f"Timed out waiting for '{needle}' to appear in the app output.")


async def wait_for_all(page, needles: list[str], timeout_seconds: int = 120) -> str:
    for _ in range(timeout_seconds):
        text = await page.locator("body").inner_text()
        if all(needle in text for needle in needles) and "Running R backend..." not in text:
            return text
        await page.wait_for_timeout(1000)
    raise RuntimeError(
        "Timed out waiting for all expected app outputs to appear:\n- "
        + "\n- ".join(needles)
    )


async def wait_for_results(page, timeout_seconds: int = 120) -> str:
    await page.get_by_role("tab", name="Diagnostics").wait_for(timeout=timeout_seconds * 1000)
    return await page.locator("body").inner_text()


async def run_browser_qa(url: str, out_dir: Path, include_case_studies: bool = False) -> None:
    from playwright.async_api import async_playwright

    out_dir.mkdir(parents=True, exist_ok=True)

    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1600, "height": 2600})

        await page.goto(url, wait_until="networkidle")
        await page.screenshot(path=str(out_dir / "01_home.png"), full_page=True)

        await page.get_by_role("button", name="MIC only").click()
        await page.wait_for_timeout(1500)
        await page.get_by_role("button", name="Run analysis").click()
        mic_text = await wait_for_results(page)
        await page.screenshot(path=str(out_dir / "02_mic_only_result.png"), full_page=True)
        await page.get_by_role("tab", name="Diagnostics").click()
        await page.wait_for_timeout(750)
        mic_diag_text = await page.locator("body").inner_text()
        await page.get_by_role("tab", name="Reports").click()
        await page.wait_for_timeout(750)
        mic_report_text = await page.locator("body").inner_text()

        await page.goto(url, wait_until="networkidle")
        await page.get_by_role("button", name="Numeric features").click()
        await page.wait_for_timeout(1500)
        await page.get_by_role("button", name="Run analysis").click()
        numeric_text = await wait_for_results(page)
        await wait_for_all(
            page,
            ["Genotype / structure map"],
        )
        await page.screenshot(path=str(out_dir / "03_numeric_external_result.png"), full_page=True)
        await page.get_by_role("tab", name="Diagnostics").click()
        await page.wait_for_timeout(750)
        numeric_diag_text = await page.locator("body").inner_text()
        await page.get_by_role("tab", name="Reports").click()
        await page.wait_for_timeout(750)
        numeric_report_text = await page.locator("body").inner_text()

        case_study_texts: dict[str, str] = {}
        case_study_diag_texts: dict[str, str] = {}
        if include_case_studies:
            for label, screenshot_name in [
                ("S. pneumoniae", "04_spneumoniae_result.png"),
                ("S. suis", "05_suis_result.png"),
            ]:
                await page.goto(url, wait_until="networkidle")
                await page.get_by_role("button", name=label).click()
                await page.wait_for_timeout(1500)
                await page.get_by_role("button", name="Run analysis").click()
                case_text = await wait_for_results(page, timeout_seconds=300)
                await page.screenshot(path=str(out_dir / screenshot_name), full_page=True)
                await page.get_by_role("tab", name="Diagnostics").click()
                await page.wait_for_timeout(750)
                case_diag_text = await page.locator("body").inner_text()
                case_study_texts[label] = case_text
                case_study_diag_texts[label] = case_diag_text

        await browser.close()

    checks = {
        "mic_only": {
            "Phenotype map": "Phenotype map" in mic_text,
            "Goodness-of-fit summaries": "Goodness-of-fit summaries" in mic_diag_text,
            "Download bundles": "Download bundles" in mic_report_text,
            "Download report (.html)": "Download report (.html)" in mic_report_text,
        },
        "numeric_external": {
            "Genotype / structure map": "Genotype / structure map" in numeric_text,
            "Side-by-side phenotype and genotype / structure maps": "Side-by-side phenotype and genotype / structure maps" in numeric_text,
            "Cluster scree diagnostics": "Cluster scree diagnostics" in numeric_diag_text,
            "Reference-distance relationship": "Reference-distance relationship" in numeric_text,
            "Goodness-of-fit summaries": "Goodness-of-fit summaries" in numeric_diag_text,
            "Download output bundle (.zip)": "Download output bundle (.zip)" in numeric_report_text,
        },
    }

    if include_case_studies:
        for label in ["S. pneumoniae", "S. suis"]:
            checks[label] = {
                "Phenotype map": "Phenotype map" in case_study_texts.get(label, ""),
                "Goodness-of-fit summaries": "Goodness-of-fit summaries" in case_study_diag_texts.get(label, ""),
            }

    failures = []
    for workflow, workflow_checks in checks.items():
        for label, ok in workflow_checks.items():
            print(f"[{'OK' if ok else 'FAIL'}] {workflow}: {label}")
            if not ok:
                failures.append(f"{workflow}: {label}")

    if failures:
        raise SystemExit(
            "Browser QA failed:\n- " + "\n- ".join(failures)
        )

    print(f"Browser QA completed successfully. Screenshots written to {out_dir}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Run a lightweight browser-level QA pass for the Streamlit app.")
    parser.add_argument(
        "--url",
        default="http://127.0.0.1:8502",
        help="Running Streamlit app URL (default: %(default)s)",
    )
    parser.add_argument(
        "--out-dir",
        default=".tmp_browser_artifacts",
        help="Directory for screenshots (default: %(default)s)",
    )
    parser.add_argument(
        "--include-case-studies",
        action="store_true",
        help="Also run the larger packaged S. pneumoniae and S. suis demos.",
    )
    args = parser.parse_args()

    try:
        asyncio.run(run_browser_qa(
            url=args.url,
            out_dir=Path(args.out_dir),
            include_case_studies=args.include_case_studies,
        ))
    except ImportError as exc:
        raise SystemExit(
            "Playwright is required for browser QA. Install it in a Python environment first."
        ) from exc

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
