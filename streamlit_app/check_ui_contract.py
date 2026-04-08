from __future__ import annotations

from pathlib import Path
import sys


APP_PATH = Path(__file__).resolve().parent / "app.py"


def main() -> int:
    try:
        from streamlit.testing.v1 import AppTest
    except Exception as exc:  # noqa: BLE001
        print(
            "Streamlit UI contract check requires streamlit with testing support installed.",
            file=sys.stderr,
        )
        print(f"Import error: {exc}", file=sys.stderr)
        return 2

    app = AppTest.from_file(str(APP_PATH))
    app.run(timeout=60)

    title_values = [node.value for node in app.title]
    assert "amrcartography" in title_values, "App title is missing."

    captions = [node.value for node in app.caption]
    assert any("Phenotype-first cartography app" in text for text in captions), (
        "Expected app caption describing the phenotype-first workflow."
    )

    markdown_blocks = [node.value for node in app.markdown]
    assert any("one doubling dilution" in block for block in markdown_blocks), (
        "Expected calibration note in app shell."
    )

    sidebar_headers = [node.value for node in app.sidebar.header]
    assert "Phenotype-first workflow" in sidebar_headers, "Sidebar phenotype-first header is missing."

    button_labels = [node.label for node in app.button]
    assert "MIC only" in button_labels, "Expected bundled MIC-only demo button."
    assert "Numeric features" in button_labels, "Expected bundled numeric feature demo button."
    assert "Character features" in button_labels, "Expected bundled character feature demo button."

    uploader_labels = [node.label for node in app.file_uploader]
    assert "Phenotype MIC CSV" in uploader_labels, "Phenotype file uploader is missing."

    print("Streamlit UI contract check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
