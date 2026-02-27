from __future__ import annotations

import csv
import datetime as dt
import json
import os
import time
from collections import defaultdict
from typing import Any

from ansible.plugins.callback import CallbackBase


TRUE_VALUES = {"1", "true", "yes", "on"}


def _env_flag_enabled(name: str) -> bool:
    return os.getenv(name, "").strip().lower() in TRUE_VALUES


def _safe_text(value: Any) -> str:
    if value is None:
        return ""
    return str(value).replace("\n", " ").strip()


class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "aggregate"
    CALLBACK_NAME = "idops_task_timing"
    CALLBACK_NEEDS_WHITELIST = False

    def __init__(self) -> None:
        super().__init__()
        self._enabled = _env_flag_enabled("IDOPS_BENCHMARK")
        self._task_starts: dict[tuple[str, str], float] = {}
        self._task_records: list[dict[str, Any]] = []
        self._stage_totals: dict[str, float] = defaultdict(float)
        self._current_play_name = ""
        self._run_started_epoch = time.time()
        self._jsonl_handle = None
        self._csv_handle = None
        self._csv_writer = None
        self._run_dir = ""
        self._summary_path = ""

        if not self._enabled:
            return

        run_dir = os.getenv("IDOPS_BENCHMARK_DIR", "").strip()
        if not run_dir:
            timestamp = dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")
            run_dir = os.path.join(os.getcwd(), "logs", "benchmark", timestamp)
        os.makedirs(run_dir, exist_ok=True)

        self._run_dir = run_dir
        jsonl_path = os.path.join(run_dir, "task_timings.jsonl")
        csv_path = os.path.join(run_dir, "task_timings.csv")
        self._summary_path = os.path.join(run_dir, "timing_summary.json")

        self._jsonl_handle = open(jsonl_path, "a", encoding="utf-8")
        self._csv_handle = open(csv_path, "a", newline="", encoding="utf-8")
        self._csv_writer = csv.DictWriter(
            self._csv_handle,
            fieldnames=[
                "task_name",
                "status",
                "duration_seconds",
                "host",
                "stage",
                "play_name",
                "task_path",
                "task_action",
            ],
        )
        if self._csv_handle.tell() == 0:
            self._csv_writer.writeheader()

    def _stage_from_task_path(self, task_path: str) -> str:
        if "tasks/provision-preflight.yml" in task_path:
            return "preflight"
        if "tasks/provision-image-cache.yml" in task_path:
            return "image-cache"
        if "tasks/provision-instances.yml" in task_path:
            return "provision"
        if "tasks/provision-runtime.yml" in task_path:
            return "runtime"
        if "tasks/cleanup.yml" in task_path:
            return "cleanup"
        if "tasks/ping.yml" in task_path:
            return "ping"
        return "other"

    def _write_record(self, record: dict[str, Any]) -> None:
        if not self._enabled:
            return
        if self._jsonl_handle is not None:
            self._jsonl_handle.write(json.dumps(record, sort_keys=True) + "\n")
            self._jsonl_handle.flush()
        if self._csv_writer is not None:
            self._csv_writer.writerow(record)
            if self._csv_handle is not None:
                self._csv_handle.flush()

    def _record_result(self, result: Any, status: str) -> None:
        if not self._enabled:
            return

        task = getattr(result, "_task", None)
        host = getattr(result, "_host", None)
        task_uuid = getattr(task, "_uuid", "")
        host_name = host.get_name() if host is not None else "unknown"
        start_key = (host_name, task_uuid)
        started = self._task_starts.pop(start_key, None)
        ended = time.monotonic()
        duration = max(0.0, ended - started) if started is not None else 0.0

        task_name = _safe_text(getattr(task, "get_name", lambda: "")())
        task_path = _safe_text(getattr(task, "get_path", lambda: "")())
        task_action = _safe_text(getattr(task, "action", ""))
        stage = self._stage_from_task_path(task_path)

        record = {
            "task_name": task_name,
            "status": status,
            "duration_seconds": round(duration, 6),
            "host": host_name,
            "stage": stage,
            "play_name": _safe_text(self._current_play_name),
            "task_path": task_path,
            "task_action": task_action,
        }
        self._stage_totals[stage] += duration
        self._task_records.append(record)
        self._write_record(record)

    def _close_files(self) -> None:
        if self._jsonl_handle is not None:
            self._jsonl_handle.close()
            self._jsonl_handle = None
        if self._csv_handle is not None:
            self._csv_handle.close()
            self._csv_handle = None
            self._csv_writer = None

    def v2_playbook_on_play_start(self, play: Any) -> None:
        if not self._enabled:
            return
        self._current_play_name = play.get_name().strip() if play else ""

    def v2_runner_on_start(self, host: Any, task: Any) -> None:
        if not self._enabled:
            return
        host_name = host.get_name() if host is not None else "unknown"
        task_uuid = getattr(task, "_uuid", "")
        self._task_starts[(host_name, task_uuid)] = time.monotonic()

    def v2_runner_on_ok(self, result: Any) -> None:
        self._record_result(result, "ok")

    def v2_runner_on_failed(self, result: Any, ignore_errors: bool = False) -> None:
        self._record_result(result, "failed")

    def v2_runner_on_unreachable(self, result: Any) -> None:
        self._record_result(result, "unreachable")

    def v2_runner_on_skipped(self, result: Any) -> None:
        self._record_result(result, "skipped")

    def v2_playbook_on_stats(self, stats: Any) -> None:
        if not self._enabled:
            return

        total_wall_seconds = max(0.0, time.time() - self._run_started_epoch)
        top_slowest = sorted(
            self._task_records,
            key=lambda item: item.get("duration_seconds", 0.0),
            reverse=True,
        )[:20]

        summary = {
            "benchmark_run_dir": self._run_dir,
            "total_wall_seconds": round(total_wall_seconds, 6),
            "stage_totals_seconds": {
                stage: round(duration, 6)
                for stage, duration in sorted(
                    self._stage_totals.items(), key=lambda item: item[0]
                )
            },
            "task_count": len(self._task_records),
            "top_20_slowest_tasks": top_slowest,
        }

        with open(self._summary_path, "w", encoding="utf-8") as summary_handle:
            json.dump(summary, summary_handle, indent=2, sort_keys=True)

        self._display.display(
            f"IDOPS benchmark timing summary written to {self._summary_path}"
        )
        if top_slowest:
            self._display.display("Top 20 slowest tasks (seconds):")
            for index, task_entry in enumerate(top_slowest, start=1):
                self._display.display(
                    f"{index:02d}. {task_entry['duration_seconds']:.3f}s | "
                    f"{task_entry['stage']} | {task_entry['host']} | "
                    f"{task_entry['task_name']}"
                )

        self._close_files()
