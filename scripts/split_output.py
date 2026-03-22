#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

HEADINGS = [
    "Feature Summary",
    "Implementation Plan",
    "Backend Tasks",
    "Frontend Tasks",
    "SaaS Validation",
    "QA Checklist",
    "Documentation Updates",
    "Risks / Assumptions",
    "Final Execution Summary",
]

PLAN_HEADINGS = {
    "Feature Summary",
    "Implementation Plan",
    "Backend Tasks",
    "Frontend Tasks",
    "SaaS Validation",
    "Risks / Assumptions",
}
EXECUTION_HEADINGS = {"Final Execution Summary"}
QA_HEADINGS = {"QA Checklist"}
DOCS_HEADINGS = {"Documentation Updates"}


def normalize_heading(line: str) -> str:
    text = line.strip()
    text = re.sub(r"^#+\s*", "", text)
    text = re.sub(r"^\d+[\.)]\s*", "", text)
    text = text.strip().rstrip(":").strip()
    return text


def parse_sections(text: str) -> dict[str, str]:
    sections: dict[str, list[str]] = {}
    current: str | None = None

    for line in text.splitlines():
        heading = normalize_heading(line)
        if heading in HEADINGS:
            current = heading
            sections.setdefault(current, [])
            continue

        if current is not None:
            sections.setdefault(current, []).append(line)

    return {key: "\n".join(value).strip() for key, value in sections.items()}


def render_section(title: str, body: str) -> str:
    body = body.strip()
    if not body:
        body = "_Not provided in raw output._"
    return f"# {title}\n\n{body}\n"


def write_group(path: Path, sections: dict[str, str], wanted: set[str]) -> None:
    chunks = []
    for heading in HEADINGS:
        if heading in wanted and heading in sections:
            chunks.append(render_section(heading, sections[heading]))
    if not chunks:
        chunks.append("# Notes\n\n_No matching sections were found in raw-output.md._\n")
    path.write_text("\n".join(chunks).strip() + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: split_output.py <feature-dir>", file=sys.stderr)
        return 1

    feature_dir = Path(sys.argv[1]).resolve()
    raw_output = feature_dir / "raw-output.md"
    if not raw_output.exists():
        print(f"Missing raw output file: {raw_output}", file=sys.stderr)
        return 1

    text = raw_output.read_text(encoding="utf-8")
    if not text.strip():
        print(f"Raw output file is empty: {raw_output}", file=sys.stderr)
        return 1

    sections = parse_sections(text)

    write_group(feature_dir / "plan.md", sections, PLAN_HEADINGS)
    write_group(feature_dir / "execution.md", sections, EXECUTION_HEADINGS)
    write_group(feature_dir / "qa.md", sections, QA_HEADINGS)
    write_group(feature_dir / "docs.md", sections, DOCS_HEADINGS)

    print(f"Split complete for: {feature_dir.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
