"""
AI Code Agent

Concise, robust pipeline to:
- Generate tests and implementation
- Run pytest and fix failures
- Audit dependencies (pip-audit)
- Scan code (Bandit)
- Run mutation tests (mutmut)
"""

from pathlib import Path
import json
import os
import re
import subprocess
import sys
from typing import Dict, Optional, Tuple

from agent.models import call_model
from agent.prompts import (
    TEST_GEN_SYS,
    CODE_GEN_SYS,
    make_test_user_msg,
    make_code_user_msg,
)


# Configuration
DEFAULT_TEST_FILE = "test_solution.py"
DEFAULT_SOLUTION_FILE = "solution.py"
DEFAULT_TIMEOUT = 120
MUTATION_TIMEOUT = 900
MAX_TEST_ATTEMPTS = 3
SANDBOX_IMAGE = os.getenv("SANDBOX_IMAGE", "ai-agent-python")

def normalize_task(task: dict) -> dict:
    """Ensure task always has signature, description, and instruction fields."""

    # Default structure
    new = {
        "instruction": task.get("instruction", ""),
        "description": task.get("description", task.get("instruction", "")),
        "signature": task.get("signature", ""),  # models will infer if blank
    }

    # If no signature, give a hint to the model to invent one
    if not new["signature"]:
        new["signature"] = "# model must create a proper function signature"

    return new

def run_in_sandbox_cmd(cmd: str, timeout: int = DEFAULT_TIMEOUT) -> str:
    """Run a shell command in the Docker sandbox and return combined output."""
    try:
        result = subprocess.run(
            [
                "docker",
                "run",
                "--rm",
                "-v",
                f"{os.getcwd()}:/app",
                "-w",
                "/app",
                SANDBOX_IMAGE,
                "sh",
                "-lc",
                cmd,
            ],
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding="utf-8",
            errors="replace",
        )
        out = (result.stdout or "").rstrip()
        err = (result.stderr or "").rstrip()
        return f"{out}\n{err}".strip()
    except subprocess.TimeoutExpired:
        return f"Timeout after {timeout}s"
    except Exception as e:
        return f"Execution error: {e}"


def run_pytests(test_file: str = DEFAULT_TEST_FILE) -> str:
    """Run pytest inside the sandbox and return its output."""
    cmd = f"pytest -q {test_file}"
    return run_in_sandbox_cmd(cmd)


def run_mutation_tests(
    solution_file: str = DEFAULT_SOLUTION_FILE, test_file: str = DEFAULT_TEST_FILE
) -> Tuple[str, Optional[float]]:
    """Run mutmut and return raw output and parsed score, if any."""
    setup_cfg = (
        "[mutmut]\n"
        f"paths_to_mutate={solution_file}\n"
        f"runner=pytest -x {test_file}\n"
        "tests_dir=.\n"
    )
    cmd = (
        "pip install -q mutmut && "
        f"printf '%s' \"{setup_cfg}\" > setup.cfg && "
        "mutmut run 2>&1 && mutmut results 2>&1"
    )
    out = run_in_sandbox_cmd(cmd, timeout=MUTATION_TIMEOUT)
    return out, _parse_mutation_score(out)


def _parse_mutation_score(output: str) -> Optional[float]:
    """Parse mutation score from mutmut results output."""
    # Format 1: Progress line "X/Y  🎉 killed 🫥 skipped ⏰ timeout 🤔 suspicious 🙁 survived 🔇 no_coverage"
    # Look for the final completion line where X == Y
    for line in output.split('\n'):
        match = re.search(r'(\d+)/(\d+)', line)
        if not match:
            continue
        current, total = int(match.group(1)), int(match.group(2))
        if current == total and total > 0:
            # Extract all numbers from this line
            numbers = [int(n) for n in re.findall(r'\d+', line)]
            # Format: [current, total, killed, skipped, timeout, suspicious, survived, no_coverage]
            if len(numbers) >= 7:
                killed = numbers[2]
                return 100.0 * killed / total
    
    # Format 2: Text format "NN mutants, MM killed"
    m = re.search(r"(\d+)\s+mutants?,\s+(\d+)\s+killed", output, re.IGNORECASE)
    if m:
        total, killed = int(m.group(1)), int(m.group(2))
        return (100.0 * killed / total) if total else None

    # Format 3: Sum categories from results summary
    def _count(label: str) -> int:
        m2 = re.search(rf"\b{label}\s+(\d+)\b", output, re.IGNORECASE)
        return int(m2.group(1)) if m2 else 0

    killed = _count("killed")
    survived = _count("survived")
    total = (
        killed
        + survived
        + _count("suspicious")
        + _count("timeout")
        + _count("skipped")
    )
    if total:
        return 100.0 * killed / total

    # No mutants
    if "no mutants" in output.lower():
        return 100.0

    return None


def run_security_scan(solution_file: str = DEFAULT_SOLUTION_FILE) -> Tuple[str, Dict[str, int]]:
    """Run Bandit and return raw output and summarized severities."""
    cmd = f"pip install -q bandit && bandit -r {solution_file} -f json 2>&1 || true"
    out = run_in_sandbox_cmd(cmd)
    return out, _parse_bandit_output(out)


def _parse_bandit_output(output: str) -> Dict[str, int]:
    summary = {"high": 0, "medium": 0, "low": 0, "total": 0}
    try:
        start = output.find("{")
        end = output.rfind("}") + 1
        if start < 0 or end <= start:
            return summary
        data = json.loads(output[start:end])
        for issue in data.get("results", []):
            sev = issue.get("issue_severity", "").lower()
            if sev in summary:
                summary[sev] += 1
                summary["total"] += 1
        if summary["total"] == 0:
            for fm in data.get("metrics", {}).values():
                if not isinstance(fm, dict):
                    continue
                summary["high"] = max(summary["high"], int(fm.get("SEVERITY.HIGH", 0)))
                summary["medium"] = max(summary["medium"], int(fm.get("SEVERITY.MEDIUM", 0)))
                summary["low"] = max(summary["low"], int(fm.get("SEVERITY.LOW", 0)))
            summary["total"] = summary["high"] + summary["medium"] + summary["low"]
    except Exception:
        for sev in ("high", "medium", "low"):
            summary[sev] = len(re.findall(rf"Severity:\s*{sev}", output, re.IGNORECASE))
        summary["total"] = summary["high"] + summary["medium"] + summary["low"]
    return summary


def run_dependency_audit() -> Tuple[str, Dict[str, int]]:
    """Run pip-audit and return raw output and a summary."""
    cmd = "pip install -q pip-audit && pip-audit --format json 2>&1 || true"
    out = run_in_sandbox_cmd(cmd, timeout=180)
    return out, _parse_pip_audit_output(out)


def _parse_pip_audit_output(output: str) -> Dict[str, int]:
    summary = {
        "vulnerabilities": 0,
        "packages_audited": 0,
        "critical": 0,
        "high": 0,
        "medium": 0,
        "low": 0,
    }
    try:
        # JSON can be a list or a dict
        start = output.find("[")
        if start < 0 or ("{" in output and output.find("{") < start):
            start = output.find("{")
        if start < 0:
            return summary
        end = output.rfind("]" if output[start] == "[" else "}") + 1
        if end <= start:
            return summary
        data = json.loads(output[start:end])

        if isinstance(data, list):
            summary["vulnerabilities"] = len(data)
            summary["packages_audited"] = len({d.get("name") for d in data if "name" in d})
        elif isinstance(data, dict) and "dependencies" in data:
            deps = data["dependencies"]
            if isinstance(deps, list):
                summary["packages_audited"] = len(deps)
                for dep in deps:
                    vulns = dep.get("vulns", [])
                    summary["vulnerabilities"] += len(vulns)
                    for v in vulns:
                        sev = (v.get("severity", "") or "").lower()
                        if sev in summary:
                            summary[sev] += 1
            elif isinstance(deps, dict):
                summary["packages_audited"] = len(deps)
                for pkg in deps.values():
                    vulns = pkg.get("vulns", [])
                    summary["vulnerabilities"] += len(vulns)
                    for v in vulns:
                        sev = (v.get("severity", "") or "").lower()
                        if sev in summary:
                            summary[sev] += 1
    except Exception:
        m = re.search(r"Found (\d+) vulnerabilit", output, re.IGNORECASE)
        if m:
            summary["vulnerabilities"] = int(m.group(1))
        m = re.search(r"(\d+) packages? audited", output, re.IGNORECASE)
        if m:
            summary["packages_audited"] = int(m.group(1))
    return summary


def extract_function_name(signature: str) -> str:
    """Extract function name from a Python signature string."""
    if not signature or not signature.strip():
        return ""
    
    # Handle comments or empty signatures
    if signature.startswith("#") or "def " not in signature:
        return ""
    
    try:
        # Find "def function_name("
        def_idx = signature.index("def ")
        paren_idx = signature.index("(", def_idx)
        return signature[def_idx + 4:paren_idx].strip()
    except (ValueError, IndexError):
        return ""


def extract_function_name_from_code(code: str) -> str:
    """Extract the first function name from Python code."""
    for line in code.split('\n'):
        line = line.strip()
        if line.startswith("def ") and "(" in line:
            try:
                return line[4:line.index("(")].strip()
            except (ValueError, IndexError):
                continue
    return ""


def _strip_code_markers(code: str) -> str:
    """Remove markdown fences from model output, if any."""
    return code.replace("```python", "").replace("```", "").strip()


def _add_import_if_missing(test_code: str, module_name: str, func_name: str) -> str:
    """Ensure tests import the function under test."""
    if not func_name:
        return test_code
    import_line = f"from {module_name} import {func_name}"
    return test_code if import_line in test_code else f"{import_line}\n\n{test_code}"


def _run_test_loop(task: Dict, test_file: str, solution_file: str) -> bool:
    """Run pytest and ask the model to fix failures up to a limit."""
    for attempt in range(1, MAX_TEST_ATTEMPTS + 1):
        print(f"Attempt {attempt}/{MAX_TEST_ATTEMPTS}")
        result = run_pytests(test_file)
        print(result)
        if "FAILED" not in result and "ERROR" not in result:
            print("Tests passed")
            return True

        with open(solution_file, "r", encoding="utf-8") as f:
            current = f.read()
        fixed = call_model(CODE_GEN_SYS, make_code_user_msg(task, impl=current, feedback=result))
        fixed = _strip_code_markers(fixed)
        with open(solution_file, "w", encoding="utf-8") as f:
            f.write(fixed)

    print("Max attempts reached; tests still failing")
    return False


def _run_security_pipeline(solution_file: str) -> None:
    print("Running dependency audit (pip-audit)...")
    dep_out, dep = run_dependency_audit()
    if dep["vulnerabilities"]:
        print("Vulnerable dependencies:")
        for sev in ("critical", "high", "medium", "low"):
            if dep.get(sev, 0):
                print(f"  {sev.capitalize()}: {dep[sev]}")
        print(f"  Total: {dep['vulnerabilities']}")
        if dep.get("critical", 0) or dep.get("high", 0):
            print("\nDetailed vulnerability report:")
            print(dep_out)
    else:
        print(f"No vulnerable dependencies ({dep['packages_audited']} packages audited)")

    print("\nRunning security scan (Bandit)...")
    sec_out, sec = run_security_scan(solution_file)
    if sec["total"]:
        print("Security issues:")
        for sev in ("high", "medium", "low"):
            if sec.get(sev, 0):
                print(f"  {sev.capitalize()}: {sec[sev]}")
        print(f"  Total: {sec['total']}")
        if sec.get("high", 0) or sec.get("medium", 0):
            print("\nDetailed security report:")
            print(sec_out)
    else:
        print("No security issues")


def _run_mutation_pipeline(solution_file: str, test_file: str) -> None:
    print("\nRunning mutation testing (mutmut)...")
    mut_out, score = run_mutation_tests(solution_file, test_file)
    print(mut_out)
    if score is not None:
        print(f"Mutation score: {score:.2f}%")
    else:
        print("Mutation score unavailable (see output above)")


def run_task(task_input) -> None:
    """End-to-end pipeline for a single task, supporting dict or file path."""

    # determine if we got a dict or filename
    if isinstance(task_input, dict):
        task = normalize_task(task_input)
    else:
        with open(task_input, "r", encoding="utf-8") as f:
            task = normalize_task(json.load(f))

    # set filenames
    func_name = extract_function_name(task.get("signature", ""))
    test_file = DEFAULT_TEST_FILE
    solution_file = DEFAULT_SOLUTION_FILE
    module_name = Path(solution_file).stem

    print("Generating tests...")
    tests = call_model(TEST_GEN_SYS, make_test_user_msg(task))
    tests = _strip_code_markers(tests)
    tests = _add_import_if_missing(tests, module_name, func_name)
    with open(test_file, "w", encoding="utf-8") as f:
        f.write(tests)

    print("Generating initial code...")
    code = call_model(CODE_GEN_SYS, make_code_user_msg(task))
    code = _strip_code_markers(code)
    with open(solution_file, "w", encoding="utf-8") as f:
        f.write(code)
    
    # If we couldn't extract function name from signature, try from generated code
    if not func_name:
        func_name = extract_function_name_from_code(code)
        if func_name:
            # Re-add import to tests with the correct function name
            tests = _add_import_if_missing(tests, module_name, func_name)
            with open(test_file, "w", encoding="utf-8") as f:
                f.write(tests)

    print("Running tests in sandbox...")
    if not _run_test_loop(task, test_file, solution_file):
        print("Task incomplete: tests failing")
        return

    _run_security_pipeline(solution_file)
    _run_mutation_pipeline(solution_file, test_file)
    print("\nTask complete")

def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python -m agent.agent <task-file>")
        sys.exit(1)
    task_file = sys.argv[1]
    if not os.path.exists(task_file):
        print(f"Task file not found: {task_file}")
        sys.exit(1)
    try:
        run_task(task_file)
    except KeyboardInterrupt:
        print("\nInterrupted by user")
        sys.exit(130)


if __name__ == "__main__":
    # Natural language input
    if len(sys.argv) >= 2 and not os.path.exists(sys.argv[1]):
        task_text = " ".join(sys.argv[1:])
        run_task({"instruction": task_text})
        sys.exit(0)

    # JSON file input
    if len(sys.argv) >= 2 and sys.argv[1].endswith(".json"):
        run_task(sys.argv[1])
        sys.exit(0)

    print("Usage:")
    print("  python -m agent.agent task.json")
    print('  python -m agent.agent "write a function to do X"')


