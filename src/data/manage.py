# manage.py
## Manages persistent game data

from pathlib import Path
import json
import re

GAME_LOG_PATH = "C:/Users/rocke/Documents/rpg-simulator/game_log.txt"
RUN_DATA_PATH = "C:/Users/rocke/Documents/rpg-simulator/src/data/run_data.json"

# matches a run delimiter, e.g. "[2026-06-17 22:16:43] --- [res://game_log.txt] Initialized ---"
_DELIMITER = re.compile(
    r"^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] --- \[.*?\] Initialized ---"
)


def _sanitize(line):
    # Godot prints dictionaries with tokens that aren't valid JSON. Coerce them
    # into JSON before handing the line to json.loads.

    # StringName: &"GambleAttack" -> "GambleAttack"
    line = line.replace('&"', '"')

    # null sentinel: <null> -> null
    line = re.sub(r"<null>", "null", line)

    # object / ability refs, quoted in a single pass so none is wrapped twice:
    #   (res://path.gd):<GDScript#-123>, PlayerController:<Node#123>,
    #   <RefCounted#-123>, <Node2D#123>
    line = re.sub(
        r"(?:\(res://[^)]*\):)?(?:[A-Za-z_][A-Za-z0-9_]*:)?<[^>]*>",
        lambda m: json.dumps(m.group(0)),
        line,
    )

    # vectors / tuples: (6, 19) -> [6, 19]
    line = re.sub(
        r"\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)",
        r"[\1, \2]",
        line,
    )

    return line


def _parse_log():
    log = Path(GAME_LOG_PATH)
    if not log.exists():
        return {}

    runs = {}
    current = None

    for raw in log.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue

        match = _DELIMITER.match(line)
        if match:
            # new run; bucket subsequent data lines under its timestamp
            current = match.group(1)
            runs.setdefault(current, [])
            continue

        if current is None:
            # data before any delimiter; ignore
            continue

        try:
            runs[current].append(json.loads(_sanitize(line)))
        except json.JSONDecodeError:
            # skip lines that can't be coerced into JSON
            continue

    # merge into any previously parsed data so clearing the log below doesn't
    # lose history; new runs are keyed by timestamp alongside the old ones
    data = _load_run_data()
    data.update(runs)
    Path(RUN_DATA_PATH).write_text(json.dumps(data, indent=2), encoding="utf-8")

    # clear the log so the same runs aren't parsed again on the next pass
    log.write_text("", encoding="utf-8")

    return data


def _load_run_data():
    path = Path(RUN_DATA_PATH)
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        # empty or corrupt file; start fresh
        return {}

def _init():
    # the log file must exist before we can parse it
    if not Path(GAME_LOG_PATH).exists():
        raise FileNotFoundError(GAME_LOG_PATH)

    # make sure the data file's directory exists; _parse_log writes the file
    Path(RUN_DATA_PATH).parent.mkdir(parents=True, exist_ok=True)

def main():
    # initialize data path
    _init()
    # parse log
    _parse_log()

if __name__ == "__main__":
    main()