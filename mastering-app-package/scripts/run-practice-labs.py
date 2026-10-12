"""Execute the deployed training notebooks without overwriting their sources."""

import argparse
import os
from datetime import datetime, timezone
from pathlib import Path
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lab", default="*", help="Chapter, notebook, or glob under the notebook directory")
    parser.add_argument("--timeout", type=int, default=1800, help="Seconds per cell")
    parser.add_argument("--list", choices=("true", "false"), default="false")
    parser.add_argument("--python-kernel", default="mastering_env", help="Kernel for Python notebooks")
    parser.add_argument("--workspace", type=Path, default=Path("/workspace/mastering-app-package"))
    parser.add_argument("--notebooks-dir", default="practice-labs", help="Notebook directory relative to the workspace")
    parser.add_argument("--output", type=Path, default=Path("/workspace/lab-results"))
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be positive")
    if Path(args.notebooks_dir).is_absolute() or ".." in Path(args.notebooks_dir).parts:
        parser.error("--notebooks-dir must stay inside the workspace")
    root = args.workspace / args.notebooks_dir
    if not root.is_dir():
        parser.error(f"Notebook directory not found: {root}")
    if Path(args.lab).is_absolute() or ".." in Path(args.lab).parts:
        parser.error("--lab must stay inside the notebook directory")
    notebooks = set()
    for match in root.glob(args.lab):
        if match.is_dir():
            notebooks.update(match.rglob("*.ipynb"))
        elif match.suffix == ".ipynb":
            notebooks.add(match)
    notebooks = sorted(p for p in notebooks if ".ipynb_checkpoints" not in p.parts)
    if not notebooks:
        parser.error(f"No notebooks match {args.lab!r}")
    for notebook in notebooks:
        print(notebook.relative_to(root), flush=True)
    if args.list == "true":
        return 0

    import nbformat
    from nbclient import NotebookClient

    # Bash kernels recognize a fixed prompt; venv activation must preserve it.
    os.environ["VIRTUAL_ENV_DISABLE_PROMPT"] = "1"

    output = args.output / datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    print(f"Executed notebooks: {output}", flush=True)
    for index, source in enumerate(notebooks, 1):
        relative = source.relative_to(root)
        notebook = nbformat.read(source, as_version=4)
        kernel = notebook.metadata.get("kernelspec", {}).get("name", "python3")
        language = notebook.metadata.get("kernelspec", {}).get("language", "").lower()
        if kernel == "python3" or language == "python":
            kernel = args.python_kernel
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        print(f"[{index}/{len(notebooks)}] Running {relative} (kernel: {kernel})", flush=True)
        try:
            NotebookClient(
                notebook,
                timeout=args.timeout,
                kernel_name=kernel,
                allow_errors=False,
                resources={"metadata": {"path": str(source.parent)}},
            ).execute()
        except Exception as error:
            print(f"FAILED {relative}: {error}", file=sys.stderr, flush=True)
            return 1
        finally:
            nbformat.write(notebook, target)
            print(f"Saved {target}", flush=True)
        print(f"PASSED {relative}", flush=True)
    print(f"All {len(notebooks)} notebooks passed", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
