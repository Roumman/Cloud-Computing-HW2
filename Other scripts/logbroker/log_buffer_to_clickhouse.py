import asyncio
import os
from pathlib import Path
import httpx

from config import (
    BUFFER_PATH,
    CLICKHOUSE_HOST,
    CLICKHOUSE_PORT,
    CLICKHOUSE_USER,
    CLICKHOUSE_PASSWORD,
    FLUSH_INTERVAL_SEC,
)

CLICKHOUSE_URL = f"http://{CLICKHOUSE_HOST}:{CLICKHOUSE_PORT}"
INSERT_QUERY = "INSERT INTO default.logs (ts, message) FORMAT TabSeparated"


def _escape_tsv(s: str) -> str:
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t").replace("\r", "\\r")

def _format_tsv_line(ts: str, message: str) -> str:
    return f"{ts}\t{_escape_tsv(message)}\n"

async def send_batch_to_clickhouse(rows: list[tuple[str, str]]) -> None:
    if not rows:
        return
    body = "".join(_format_tsv_line(ts, msg) for ts, msg in rows)
    params = {
        "query": INSERT_QUERY,
        "user": CLICKHOUSE_USER,
        "password": CLICKHOUSE_PASSWORD,
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        r = await client.post(CLICKHOUSE_URL, params=params, content=body)
        r.raise_for_status()

def _ensure_dir():
    Path(BUFFER_PATH).parent.mkdir(parents=True, exist_ok=True)

def append_to_buffer(lines: list[str]) -> None:
    _ensure_dir()
    ts = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())
    with open(BUFFER_PATH, "a", encoding="utf-8", errors="replace") as f:
        for line in lines:
            line = line.rstrip("\n\r")
            f.write(f"{ts}\t{line}\n")
        f.flush()
        os.fsync(f.fileno())

def read_buffer() -> list[tuple[str, str]]:
    path = Path(BUFFER_PATH)
    if not path.exists():
        return []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()
    rows = []
    for line in content.strip().split("\n"):
        if not line:
            continue
        parts = line.split("\t", 1)
        ts = parts[0] if len(parts) > 0 else ""
        msg = parts[1] if len(parts) > 1 else ""
        rows.append((ts, msg))
    return rows

def truncate_buffer() -> None:
    path = Path(BUFFER_PATH)
    if path.exists():
        path.write_text("")

async def flush_once() -> bool:
    rows = read_buffer()
    if not rows:
        return False
    last_error = None
    for attempt in range(5):
        try:
            await send_batch_to_clickhouse(rows)
            truncate_buffer()
            return True
        except Exception as e:
            last_error = e
            await asyncio.sleep(1.0 * (attempt + 1))
    raise last_error
