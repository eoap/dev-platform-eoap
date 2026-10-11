"""Report packaging and processing-image differences from PLAN.md's models."""

import argparse
import json
import subprocess
import tomllib
from pathlib import Path

MODULES = (
    "advanced-tooling",
    "application-package-patterns",
    "cwl-eoap",
    "dask-app-package",
    "eoap-contract-first",
    "event-driven-with-argo",
    "how-to",
    "inference-eoap",
    "logging-and-redirection",
    "machine-learning-process",
    "mastering-app-package",
    "ogc-api-processes-with-zoo",
    "open-reproducible-app-package",
    "quickwin",
    "quickwin-inline-code",
    "stac-eoap",
    "testing-framework",
    "zarr-cloud-native-format",
)


def packaging_issues(path):
    data = tomllib.loads(path.read_text())
    issues = []
    build = data.get("build-system", {})
    if build.get("build-backend") != "hatchling.build":
        issues.append("build backend is not Hatchling")
    if "hatchling>=1.27,<2" not in build.get("requires", []):
        issues.append("Hatchling requirement differs from >=1.27,<2")
    project = data.get("project", {})
    if project.get("requires-python") != ">=3.12,<3.13":
        issues.append("Python compatibility differs from >=3.12,<3.13")
    for key in ("name", "description", "readme", "license", "dependencies", "urls"):
        if key not in project:
            issues.append(f"missing project {key}")
    hatch = data.get("tool", {}).get("hatch", {})
    targets = hatch.get("build", {}).get("targets", {})
    if not targets.get("wheel", {}).get("packages"):
        issues.append("wheel package directories are not explicit")
    if not targets.get("sdist", {}).get("include"):
        issues.append("sdist include paths are not explicit")
    envs = hatch.get("envs", {})
    dev = envs.get("dev", {})
    if dev.get("skip-install") is not True or dev.get("installer") != "uv":
        issues.append("development environment does not use skip-install and uv")
    if not any(
        "--require-hashes" in command
        for command in dev.get("post-install-commands", [])
    ):
        issues.append("development dependencies are not installed from a hash lock")
    for command in ("check", "format-check", "lint-check", "typecheck", "security"):
        if command not in dev.get("scripts", {}):
            issues.append(f"missing development command {command}")
    if envs.get("test", {}).get("template") != "dev":
        issues.append("test environment does not inherit dev")
    tool = data.get("tool", {})
    if not tool.get("mypy", {}).get("strict"):
        issues.append("strict mypy is not configured")
    ruff = tool.get("ruff", {})
    if ruff.get("line-length") != 100 or ruff.get("target-version") != "py312":
        issues.append("Ruff line length or Python target differs from model")
    if ruff.get("lint", {}).get("mccabe", {}).get("max-complexity") != 10:
        issues.append("Ruff complexity limit differs from model")
    return issues


def image_issues(path):
    source = path.read_text()
    issues = []
    stages = [line for line in source.splitlines() if line.upper().startswith("FROM ")]
    if len(stages) < 2 or any(
        "rockylinux/rockylinux:10.1-minimal" not in line for line in stages
    ):
        issues.append("not a two-stage Rocky Linux 10.1-minimal build")
    for token, description in (
        ("hatch build -t wheel", "missing Hatch wheel build"),
        ("hatch-v1.14.0", "Hatch 1.14.0 download is not explicit"),
        ("USER neo", "runtime does not explicitly switch to neo"),
        ("VIRTUAL_ENV=/app/venv", "runtime virtual environment differs from /app/venv"),
        ("pip check", "missing dependency consistency check"),
        ("uninstall --yes pip", "pip remains in runtime environment"),
        ("--help", "missing installed CLI smoke check"),
        ("--require-hashes", "runtime dependency installation is not hash locked"),
    ):
        if token not in source:
            issues.append(description)
    if "2000" not in source or "/home/neo" not in source:
        issues.append("runtime UID/GID or home differs from model")
    return issues


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("/data/work/github-com/eoap"))
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = {
        "scope": "e-learning modules and processing images",
        "static_audit_only": True,
        "modules": [],
    }
    for name in MODULES:
        root = args.root / name
        if not (root / ".git").exists():
            continue
        tracked = subprocess.check_output(
            [
                "git",
                "-C",
                str(root),
                "ls-files",
                "--cached",
                "--others",
                "--exclude-standard",
            ],
            text=True,
        ).splitlines()
        files = []
        for relative in sorted(set(tracked)):
            path = root / relative
            if not path.is_file() or any(
                part in {"vendor", "site", ".venv"} for part in path.parts
            ):
                continue
            if path.name == "pyproject.toml":
                files.append(
                    {
                        "path": relative,
                        "kind": "pyproject",
                        "issues": packaging_issues(path),
                    }
                )
            elif "Dockerfile" in path.name:
                files.append(
                    {
                        "path": relative,
                        "kind": "dockerfile",
                        "issues": image_issues(path),
                        "classification": "review required: processing or auxiliary service",
                    }
                )
        report["modules"].append(
            {
                "name": name,
                "branch": subprocess.check_output(
                    ["git", "-C", str(root), "branch", "--show-current"], text=True
                ).strip(),
                "commit": subprocess.check_output(
                    ["git", "-C", str(root), "rev-parse", "HEAD"], text=True
                ).strip(),
                "files": files,
                "root_pyproject": (root / "pyproject.toml").is_file(),
            }
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    for module in report["modules"]:
        files = module["files"]
        print(
            f"{module['name']}: {len(files)} files; {sum(bool(file['issues']) for file in files)} require review"
        )


if __name__ == "__main__":
    main()
