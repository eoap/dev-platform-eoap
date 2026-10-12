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


MODEL_EXCEPTIONS = {
    ("dask-app-package", "Dockerfile.acceptance"): "development acceptance harness",
    ("zarr-cloud-native-format", "containers/yq/Dockerfile"): "upstream Go CLI; no module-owned Python package",
    ("zarr-cloud-native-format", "docker/titiler-eopf-patched/Dockerfile"): "upstream TiTiler service; outside processing-image scope",
}


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
    for package in targets.get("wheel", {}).get("packages", []):
        if not (path.parent / package).is_dir():
            issues.append(f"declared wheel package directory does not exist: {package}")
    for key in ("Documentation", "Source", "Issues"):
        if key not in project.get("urls", {}):
            issues.append(f"missing project URL {key}")
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
    complexity = ruff.get("lint", {}).get("mccabe", {}).get("max-complexity")
    if not isinstance(complexity, int) or not 0 < complexity <= 10:
        issues.append("Ruff complexity limit exceeds model or is missing")
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
    parser.add_argument(
        "--checkout", action="append", default=[], metavar="MODULE=PATH",
        help="Audit an isolated feature checkout instead of the original working tree",
    )
    args = parser.parse_args()
    checkouts = {}
    for override in args.checkout:
        module, separator, location = override.partition("=")
        if not separator or module not in MODULES or not location:
            parser.error("--checkout requires a known MODULE=PATH")
        checkouts[module] = Path(location).resolve()
    report = {
        "scope": "e-learning modules and processing images",
        "static_audit_only": True,
        "modules": [],
    }
    for name in MODULES:
        root = checkouts.get(name, args.root / name)
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
        notebook_image_recipes = []
        for relative in sorted(set(tracked)):
            path = root / relative
            if not path.is_file() or any(
                part in {"vendor", "site", ".venv", ".ipynb_checkpoints"} for part in path.parts
            ):
                continue
            if path.suffix == ".ipynb":
                notebook = json.loads(path.read_text())
                for index, cell in enumerate(notebook.get("cells", [])):
                    source = "".join(cell.get("source", []))
                    if cell.get("cell_type") == "code" and "FROM " in source and "Dockerfile" in source:
                        notebook_image_recipes.append({
                            "path": relative,
                            "cell": index,
                            "requires_review": True,
                            "reason": "Notebook generates a container recipe; file checks alone do not validate it",
                        })
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
                        "classification": MODEL_EXCEPTIONS.get(
                            (name, relative), "module-owned Python processing image"
                        ),
                        "model_exception": (name, relative) in MODEL_EXCEPTIONS,
                    }
                )
        report["modules"].append(
            {
                "name": name,
                "checkout": str(root),
                "branch": subprocess.check_output(
                    ["git", "-C", str(root), "branch", "--show-current"], text=True
                ).strip(),
                "commit": subprocess.check_output(
                    ["git", "-C", str(root), "rev-parse", "HEAD"], text=True
                ).strip(),
                "files": files,
                "root_pyproject": (root / "pyproject.toml").is_file(),
                "notebook_image_recipes": notebook_image_recipes,
            }
        )
    platform = Path(__file__).resolve().parents[1]
    platform_files = []
    classifications = {
        "event-driven-with-argo/containers/stage-out/Dockerfile": "platform-owned Python processing image",
        "event-driven-with-argo/containers/validate-schema/Dockerfile": "third-party JSON Schema wheel runtime; no owned application wheel",
        "dask-gateway/Dockerfile.pde-worker": "optional course processing image; mirror of tested Dask source",
    }
    for path in sorted(platform.rglob("Dockerfile*")):
        relative = path.relative_to(platform).as_posix()
        if any(part.startswith(".") or part in {"vendor", "site"} for part in path.relative_to(platform).parts):
            continue
        classification = classifications.get(relative, "shared editor, infrastructure or service image; outside processing scope")
        processing = relative in {"event-driven-with-argo/containers/stage-out/Dockerfile", "dask-gateway/Dockerfile.pde-worker"}
        platform_files.append({"path": relative, "kind": "dockerfile", "classification": classification, "processing_model_applies": processing, "issues": image_issues(path) if processing else []})
    for path in sorted((platform / "event-driven-with-argo/containers").rglob("pyproject.toml")):
        platform_files.append({"path": path.relative_to(platform).as_posix(), "kind": "pyproject", "issues": packaging_issues(path)})
    report["platform_owned_models"] = {"checkout": str(platform), "files": platform_files}

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    for module in report["modules"]:
        files = module["files"]
        pending = sum(
            bool(file["issues"]) and not file.get("model_exception", False)
            for file in files
        )
        exceptions = sum(file.get("model_exception", False) for file in files)
        print(
            f"{module['name']}: {len(files)} files; {pending} require review; "
            f"{exceptions} classified exceptions; "
            f"{len(module['notebook_image_recipes'])} notebook image recipes"
        )


if __name__ == "__main__":
    main()
