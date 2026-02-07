"""
Control API for the Amazon Business Automation tool.
Exposes start run and status for the frontend.
"""
import json
import os
import subprocess
import sys
import threading
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="Amazon Automation API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Status file lives next to this script (backend dir)
BACKEND_DIR = Path(__file__).resolve().parent
STATUS_FILE = BACKEND_DIR / "automation_status.json"

DEFAULT_STATUS = {
    "status": "idle",  # idle | running | success | error
    "lastRun": None,
    "message": None,
}


def _read_status() -> dict:
    if not STATUS_FILE.exists():
        return DEFAULT_STATUS.copy()
    try:
        data = json.loads(STATUS_FILE.read_text(encoding="utf-8"))
        return {**DEFAULT_STATUS, **data}
    except (OSError, json.JSONDecodeError):
        return DEFAULT_STATUS.copy()


def _write_status(status: str, message: str | None = None) -> None:
    utc_now = datetime.now(timezone.utc)
    jst_now = utc_now.astimezone(ZoneInfo("Asia/Tokyo"))
    payload = {
        "status": status,
        "lastRun": jst_now.strftime("%Y-%m-%dT%H:%M:%S+09:00"),
        "message": message,
    }
    STATUS_FILE.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def _run_automation_thread() -> None:
    """Run amazon_auto in a subprocess and update status when done."""
    env = {**os.environ, "PYTHONIOENCODING": "utf-8"}
    proc = subprocess.Popen(
        [sys.executable, str(BACKEND_DIR / "amazon_auto.py")],
        cwd=str(BACKEND_DIR),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=env,
    )
    stdout, stderr = proc.communicate()
    if proc.returncode == 0:
        _write_status("success", None)
    else:
        err = (stderr or stdout or "").strip()
        if not err and stdout:
            err = stdout.strip()[-500:] if len(stdout) > 500 else stdout.strip()
        _write_status("error", err or f"Exit code {proc.returncode}")


@app.get("/api/status")
def get_status() -> dict:
    """Return current automation status (idle / running / success / error)."""
    return _read_status()


class RunResponse(BaseModel):
    started: bool
    message: str


@app.post("/api/run", response_model=RunResponse)
def start_run() -> RunResponse:
    """Start the Amazon automation once. Returns immediately; check /api/status for progress."""
    current = _read_status()
    if current["status"] == "running":
        return RunResponse(started=False, message="A run is already in progress.")
    _write_status("running", None)
    thread = threading.Thread(target=_run_automation_thread, daemon=True)
    thread.start()
    return RunResponse(started=True, message="Automation started. Check status for progress.")
