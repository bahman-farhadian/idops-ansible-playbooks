#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print benchmark summary for KVM provisioning timings."
    )
    parser.add_argument(
        "--benchmark-root",
        default="logs/benchmark",
        help="Root directory that stores benchmark run folders.",
    )
    parser.add_argument(
        "--benchmark-dir",
        default="",
        help="Specific benchmark run directory. If omitted, latest run is used.",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=20,
        help="Number of slow tasks to print from timing summary.",
    )
    return parser.parse_args()


def pick_latest_run(root: Path) -> Path:
    if not root.exists():
        raise FileNotFoundError(f"Benchmark root does not exist: {root}")
    candidates = [
        path
        for path in root.iterdir()
        if path.is_dir() and (path / "timing_summary.json").exists()
    ]
    if not candidates:
        raise FileNotFoundError(
            f"No completed benchmark runs found under: {root}"
        )
    return sorted(candidates, key=lambda path: path.stat().st_mtime, reverse=True)[0]


def parse_time_file(path: Path) -> dict[str, str]:
    data: dict[str, str] = {}
    if not path.exists():
        return data
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        data[key.strip()] = value.strip()
    return data


def main() -> int:
    args = parse_args()
    benchmark_root = Path(args.benchmark_root)
    try:
        run_dir = Path(args.benchmark_dir) if args.benchmark_dir else pick_latest_run(benchmark_root)
    except FileNotFoundError as error:
        print(f"ERROR: {error}")
        return 1

    summary_path = run_dir / "timing_summary.json"
    if not summary_path.exists():
        print(
            f"ERROR: Timing summary was not found: {summary_path}. "
            "Run make benchmark-cold first."
        )
        return 1

    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    stage_totals = summary.get("stage_totals_seconds", {})
    top_tasks = summary.get("top_20_slowest_tasks", [])
    top_limit = max(1, int(args.top))
    time_data = parse_time_file(run_dir / "time.txt")

    print(f"Benchmark run: {run_dir}")
    print("Note: apt update/upgrade excluded in benchmark-cold by design.")
    if time_data:
        print(
            "Wall clock (shell time): "
            f"real_seconds={time_data.get('real_seconds', 'n/a')} "
            f"user_seconds={time_data.get('user_seconds', 'n/a')} "
            f"sys_seconds={time_data.get('sys_seconds', 'n/a')} "
            f"max_rss_kb={time_data.get('max_rss_kb', 'n/a')}"
        )
    print(
        "Callback wall clock: "
        f"{summary.get('total_wall_seconds', 'n/a')} seconds "
        f"(task_count={summary.get('task_count', 'n/a')})"
    )

    print("\nStage totals (seconds):")
    for stage, seconds in sorted(
        stage_totals.items(), key=lambda item: float(item[1]), reverse=True
    ):
        print(f"  {stage:16} {float(seconds):9.3f}")

    print(f"\nTop {top_limit} slow tasks:")
    for index, task in enumerate(top_tasks[:top_limit], start=1):
        print(
            f"  {index:02d}. {float(task.get('duration_seconds', 0.0)):8.3f}s "
            f"| {task.get('stage', 'n/a'):11} "
            f"| {task.get('host', 'n/a'):12} "
            f"| {task.get('task_name', 'n/a')}"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
