#!/usr/bin/env python3

from __future__ import annotations

import csv
import html
import re
import urllib.request
from pathlib import Path

from bs4 import BeautifulSoup


REPO_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = REPO_ROOT / "inst" / "extdata" / "examples" / "public-mic"
DETAIL_URL = "https://wwwn.cdc.gov/ArIsolateBank/Panel/IsolateDetail?IsolateID={isolate_id}&PanelID={panel_id}"
PANEL_URL = "https://wwwn.cdc.gov/ArIsolateBank/Panel/PanelDetail?ID={panel_id}"

EXAMPLES = {
    "salmonella_enterica_mic": {
        "species_group": "Salmonella enterica",
        "panel_id": 6,
        "isolate_ids": [401, 404, 408, 410],
        "suggested_mic_cols": [
            "amoxicillin_clavulanic_acid",
            "ampicillin",
            "ceftriaxone",
            "ciprofloxacin",
            "gentamicin",
            "tetracycline",
        ],
    },
    "campylobacter_jejuni_mic": {
        "species_group": "Campylobacter jejuni",
        "panel_id": 6,
        "isolate_ids": [412, 413, 414, 415],
        "suggested_mic_cols": [
            "azithromycin",
            "ciprofloxacin",
            "erythromycin",
            "florfenicol",
            "nalidixic_acid",
            "tetracycline",
        ],
    },
    "escherichia_coli_o157_mic": {
        "species_group": "Escherichia coli O157",
        "panel_id": 6,
        "isolate_ids": [427, 428, 429, 430],
        "suggested_mic_cols": [
            "amoxicillin_clavulanic_acid",
            "ampicillin",
            "ceftriaxone",
            "ciprofloxacin",
            "gentamicin",
            "tetracycline",
        ],
    },
    "acinetobacter_baumannii_mic": {
        "species_group": "Acinetobacter baumannii",
        "panel_id": 1,
        "isolate_ids": [273, 274, 275, 276],
        "suggested_mic_cols": [
            "cefepime",
            "ceftazidime",
            "ciprofloxacin",
            "gentamicin",
            "imipenem",
            "meropenem",
            "minocycline",
        ],
    },
    "pseudomonas_aeruginosa_mic": {
        "species_group": "Pseudomonas aeruginosa",
        "panel_id": 12,
        "isolate_ids": [229, 230, 231, 232],
        "suggested_mic_cols": [
            "aztreonam",
            "cefepime",
            "ceftazidime",
            "ciprofloxacin",
            "imipenem",
            "meropenem",
            "tobramycin",
        ],
    },
    "staphylococcus_aureus_mic": {
        "species_group": "Staphylococcus aureus",
        "panel_id": 13,
        "isolate_ids": [461, 462, 463, 464],
        "suggested_mic_cols": [
            "ceftaroline",
            "clindamycin",
            "daptomycin",
            "linezolid",
            "oxacillin",
            "penicillin",
            "vancomycin",
        ],
    },
}


def fetch_text(url: str) -> str:
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "amrcartography-example-builder/0.2"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read().decode("utf-8")


def strip_tags(text: str) -> str:
    text = re.sub(r"<[^>]+>", "", text)
    text = html.unescape(text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def snake_case(text: str) -> str:
    text = strip_tags(text)
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "_", text)
    text = re.sub(r"_+", "_", text)
    text = text.strip("_")
    text = re.sub(r"_\d+$", "", text)
    return text


def parse_isolate_detail(html_text: str) -> dict:
    soup = BeautifulSoup(html_text, "html.parser")
    ar_bank_cell = None
    for bold in soup.find_all("b"):
        label = strip_tags(str(bold))
        if "AR Bank #" in label:
            ar_bank_cell = bold.find_parent("td")
            break

    if ar_bank_cell is None:
        raise RuntimeError("Failed to locate AR Bank identifier on isolate detail page.")

    ar_bank_text = " ".join(ar_bank_cell.get_text(" ", strip=True).split())
    ar_bank_match = re.search(r"AR Bank #\s*([0-9]+)\s*(.*)$", ar_bank_text)
    table_match = re.search(
        r"MIC \(&mu;g/ml\) Results and Interpretation.*?<tbody>(.*?)</tbody>",
        html_text,
        flags=re.IGNORECASE | re.DOTALL,
    )

    if ar_bank_match is None or table_match is None:
        raise RuntimeError("Failed to parse isolate detail page.")

    ar_bank_number = ar_bank_match.group(1).zfill(4)
    organism = strip_tags(ar_bank_match.group(2))
    biosample = ""
    biosample_node = soup.find(id="MainContent_lblSeqAcc")
    if biosample_node is not None:
        biosample = " ".join(biosample_node.get_text(" ", strip=True).split())
    source = ""
    source_node = soup.find(id="MainContent_lblSourceResult")
    if source_node is not None:
        source = " ".join(source_node.get_text(" ", strip=True).split())
    study_id = ""
    study_node = soup.find(id="MainContent_lblStudyIDResult")
    if study_node is not None:
        study_id = " ".join(study_node.get_text(" ", strip=True).split())

    mic_rows = re.findall(
        r"<tr>\s*<td>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>\s*</tr>",
        table_match.group(1),
        flags=re.IGNORECASE | re.DOTALL,
    )

    mic_values = {}
    for drug, mic, interpretation in mic_rows:
        mic_values[snake_case(drug)] = strip_tags(mic)
        mic_values[f"{snake_case(drug)}_int"] = strip_tags(interpretation)

    return {
        "ar_bank_id": f"AR-{ar_bank_number}",
        "study_id": study_id,
        "organism": organism,
        "biosample_accession": biosample,
        "source": source,
        **mic_values,
    }


def write_csv(path: Path, rows: list[dict]) -> list[str]:
    fieldnames = sorted({key for row in rows for key in row.keys()})
    preferred_prefix = [
        "ar_bank_id",
        "study_id",
        "species_group",
        "organism",
        "source",
        "biosample_accession",
        "panel_id",
        "panel_url",
        "detail_url",
    ]
    ordered = [name for name in preferred_prefix if name in fieldnames] + [
        name for name in fieldnames if name not in preferred_prefix
    ]

    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=ordered)
        writer.writeheader()
        writer.writerows(rows)

    return ordered


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest_rows = []

    for dataset_name, spec in EXAMPLES.items():
        panel_id = spec["panel_id"]
        panel_url = PANEL_URL.format(panel_id=panel_id)
        rows = []
        for isolate_id in spec["isolate_ids"]:
            detail_url = DETAIL_URL.format(isolate_id=isolate_id, panel_id=panel_id)
            parsed = parse_isolate_detail(fetch_text(detail_url))
            parsed["species_group"] = spec["species_group"]
            parsed["panel_id"] = str(panel_id)
            parsed["panel_url"] = panel_url
            parsed["detail_url"] = detail_url
            rows.append(parsed)

        csv_path = OUT_DIR / f"{dataset_name}.csv"
        fieldnames = write_csv(csv_path, rows)
        manifest_rows.append(
            {
                "dataset_name": dataset_name,
                "file_name": csv_path.name,
                "species_group": spec["species_group"],
                "n_isolates": str(len(rows)),
                "panel_id": str(panel_id),
                "panel_url": panel_url,
                "source_collection": "CDC & FDA Antimicrobial Resistance Isolate Bank",
                "source_reference": (
                    "Lutgring JD, Machado MJ, Benahmed FH, et al. "
                    "FDA-CDC Antimicrobial Resistance Isolate Bank: a Publicly Available "
                    "Resource To Support Research, Development, and Regulatory Requirements. "
                    "J Clin Microbiol. 2018;56(2):e01415-17."
                ),
                "source_reference_doi": "10.1128/JCM.01415-17",
                "suggested_id_col": "ar_bank_id",
                "suggested_metadata_cols": "species_group,organism,source,biosample_accession",
                "suggested_mic_cols": ",".join(spec["suggested_mic_cols"]),
                "notes": "Small public CDC AR Isolate Bank subset packaged for examples and vignette use.",
            }
        )

    write_csv(OUT_DIR / "public_mic_manifest.csv", manifest_rows)


if __name__ == "__main__":
    main()
