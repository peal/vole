#!/usr/bin/env python3
"""Fresh-process normaliser measurements and separate exact verification.

Assisted-by: OpenAI Codex (GPT-6), benchmark implementation and validation.
"""

import argparse
import hashlib
import itertools
import json
import os
from pathlib import Path
import platform
import random
import shutil
import signal
import subprocess
import tempfile
import time


REPO = Path(__file__).resolve().parents[2]
WORKER = REPO / "tst/benchmarks/normaliser-worker.g"
VARIANTS = {"Simple", "Simple2", "OrbitalNone", "OrbitalRoot", "Orbital",
            "OrbitalDeep", "OrbitalSmall", "OrbitalRegOrbit",
            "OrbitalRegOrbitChar", "OrbitalRegOrbitCross",
            "OrbitalRegOrbitCrossNoPropose"}
SELECTORS = {"smallest", "largest", "first", "most-connected",
             "most-connected-smallest", "most-connected-largest",
             "smallest-most-connected"}


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def validate_instance(spec):
    if not isinstance(spec, dict):
        raise ValueError("Each input must be a JSON object")
    n = spec.get("degree")
    if type(n) is not int or n < 1 or not isinstance(spec.get("id"), str):
        raise ValueError("Each input needs a string id and a positive integer degree")
    for field in ("generators", "ambient_generators"):
        if field == "ambient_generators" and field not in spec:
            continue
        if not isinstance(spec.get(field), list):
            raise ValueError(f"{spec['id']}: {field} must be a list")
        for p in spec[field]:
            if (not isinstance(p, list) or len(p) != n
                    or any(type(x) is not int for x in p)
                    or sorted(p) != list(range(1, n + 1))):
                raise ValueError(f"{spec['id']}: invalid permutation in {field}")


def kill_group(process):
    """Kill the owned GAP process and its Rust descendants on timeout."""
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.wait()


def run_worker(gap, job, timeout, directory, token):
    inp = directory / f"{token}.input.json"
    out = directory / f"{token}.output.json"
    log = directory / f"{token}.log"
    inp.write_text(json.dumps(job))
    quote = lambda value: json.dumps(str(value), ensure_ascii=False)
    command = (f"Read({quote(WORKER)}); "
               f"VoleBenchmarkWorker({quote(inp)}, {quote(out)}); QUIT;")
    start = time.perf_counter_ns()
    with log.open("wb") as stream:
        process = subprocess.Popen(
            [gap, "-A", "-q", "-b", "--quitonbreak", "-c", command],
            cwd=REPO, stdout=stream, stderr=subprocess.STDOUT,
            start_new_session=True)
        try:
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            kill_group(process)
            return {"status": "timeout", "process_wall_ns": time.perf_counter_ns() - start}
        except BaseException:
            kill_group(process)
            raise
    elapsed = time.perf_counter_ns() - start
    if process.returncode != 0 or not out.exists():
        return {"status": "crash", "returncode": process.returncode,
                "process_wall_ns": elapsed, "log": log.read_text(errors="replace")}
    try:
        result = json.loads(out.read_text())
        for field in ("input_order", "ambient_order"):
            expected = job["instance"].get("expected_" + field)
            if expected is not None and field in result and result[field] != str(expected):
                raise ValueError(f"Input catalogue mismatch: {field}={result[field]}, expected {expected}")
        for source in result.get("loaded_sources", {}).values():
            if not Path(source).resolve().is_relative_to(REPO):
                raise ValueError(f"Loaded source outside the reviewed checkout: {source}")
        result["loaded_source_sha256"] = {
            key: digest(path) for key, path in result.get("loaded_sources", {}).items()}
    except (ValueError, OSError) as error:
        return {"status": "crash", "process_wall_ns": elapsed, "error": str(error),
                "log": log.read_text(errors="replace")}
    return {"status": "finished", "process_wall_ns": elapsed, "result": result}


def verification_status(observation):
    if observation["status"] != "finished":
        return "verification_" + observation["status"]
    result = observation["result"]
    if not result["valid_subgroup"]:
        return "wrong"
    if not result["oracle_available"]:
        return "oracle_unavailable"
    return "verified" if result["equal"] else "wrong"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inputs", type=Path, help="JSONL: id, degree, generators, optional ambient_generators")
    parser.add_argument("--output", required=True, type=Path, help="New output directory")
    parser.add_argument("--gap", default="gap")
    parser.add_argument("--backends", default="gap,refiner:Orbital,refiner:OrbitalRegOrbit,refiner:OrbitalRegOrbitCross,direct,by-orbits")
    parser.add_argument("--selectors", default="most-connected-smallest")
    parser.add_argument("--shortcut", choices=["both", "on", "off"], default="both")
    parser.add_argument("--repeats", type=int, default=5)
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--verify-timeout", type=float, default=60)
    parser.add_argument("--seed", type=int, default=20261004)
    args = parser.parse_args()
    gap = shutil.which(args.gap)
    if gap is None:
        parser.error("GAP executable not found")
    if os.name != "posix":
        parser.error("This runner requires POSIX process groups for descendant cleanup")
    if min(args.repeats, args.timeout, args.verify_timeout) <= 0:
        parser.error("Repeat counts and deadlines must be positive")
    binary = REPO / "rust/target/release/vole"
    if not binary.exists():
        parser.error("Build first: cargo build --release --manifest-path rust/Cargo.toml")
    try:
        specs = [json.loads(line) for line in args.inputs.read_text().splitlines() if line.strip()]
        for spec in specs:
            validate_instance(spec)
        if not specs or len({s["id"] for s in specs}) != len(specs):
            raise ValueError("Inputs must be nonempty and have unique ids")
        backends = list(dict.fromkeys(args.backends.split(",")))
        selectors = list(dict.fromkeys(args.selectors.split(",")))
        for backend in backends:
            if backend not in {"gap", "direct", "by-orbits"} and backend not in {f"refiner:{v}" for v in VARIANTS}:
                raise ValueError(f"Unknown backend: {backend}")
        if not set(selectors) <= SELECTORS:
            raise ValueError("Unknown selector")
    except (ValueError, OSError) as error:
        parser.error(str(error))
    if args.output.exists():
        parser.error("Output directory already exists; choose a new directory")
    args.output.mkdir(parents=True)
    (args.output / "inputs.jsonl").write_text("".join(json.dumps(s) + "\n" for s in specs))
    git = lambda *cmd: subprocess.check_output(["git", *cmd], cwd=REPO, text=True).strip()
    metadata = {"schema_version": 1, "assistance": "OpenAI Codex (GPT-6)",
                "argv": vars(args) | {"inputs": str(args.inputs), "output": str(args.output)},
                "gap_executable": gap, "git_commit": git("rev-parse", "HEAD"),
                "working_tree": git("status", "--porcelain"),
                "tracked_diff_sha256": hashlib.sha256(git("diff", "HEAD").encode()).hexdigest(),
                "binary_sha256": digest(binary), "worker_sha256": digest(WORKER),
                "runner_sha256": digest(__file__), "platform": platform.platform(),
                "python": platform.python_version(), "cpu": platform.processor(),
                "logical_cpu_count": os.cpu_count(), "memory_measurement": "not_collected"}
    rustc = shutil.which("rustc")
    metadata["rustc"] = (subprocess.check_output([rustc, "--version", "--verbose"], text=True)
                         if rustc else "unavailable")
    (args.output / "tracked.patch").write_text(git("diff", "--binary", "HEAD") + "\n")
    (args.output / "metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")
    rng = random.Random(args.seed)
    shortcuts = [False, True] if args.shortcut == "both" else [args.shortcut == "on"]
    trials = list(itertools.product(specs, range(args.repeats), selectors, shortcuts))
    rng.shuffle(trials)
    bad = False
    with (args.output / "observations.jsonl").open("w") as log, tempfile.TemporaryDirectory(prefix="vole-benchmark-") as tmp:
        directory = Path(tmp)
        def emit(event):
            log.write(json.dumps(event) + "\n")
            log.flush()
        for trial, (spec, repeat, selector, shortcut) in enumerate(trials):
            order = backends.copy()
            rng.shuffle(order)
            # All paired methods receive the same GAP random-source seed.
            trial_seed = rng.randrange(1, 2**31)
            measured = {}
            for backend in order:
                job = {"operation": "solve", "instance": spec, "backend": backend,
                       "shortcut": shortcut, "selector": selector, "seed": trial_seed}
                observation = run_worker(gap, job, args.timeout, directory, f"{trial}-{backend}")
                measured[backend] = observation
                emit({"event": "measurement", "trial": trial, "instance": spec["id"],
                      "repeat": repeat, "backend": backend, "seed": trial_seed,
                      "selector": selector, "shortcut": shortcut, **observation})
                print(f"{spec['id']} repeat={repeat} {backend} shortcut={shortcut}: {observation['status']}", flush=True)
                bad |= observation["status"] == "crash"
            oracle = measured.get("gap", {})
            for backend, observation in measured.items():
                if backend == "gap" or observation["status"] != "finished":
                    continue
                job = {"operation": "verify", "instance": spec, "seed": trial_seed,
                       "result": observation["result"]}
                if oracle.get("status") == "finished":
                    job["reference"] = oracle["result"]
                verification = run_worker(gap, job, args.verify_timeout, directory, f"{trial}-{backend}-verify")
                status = verification_status(verification)
                emit({"event": "verification", "trial": trial, "instance": spec["id"],
                      "backend": backend, **verification, "status": status})
                bad |= status in {"wrong", "verification_crash"}
                print(f"  {backend}: {status}", flush=True)
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
