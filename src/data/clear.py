# clear.py
## Clears game data to initial state

from pathlib import Path

GAME_LOG_PATH = "C:/Users/rocke/Documents/rpg-simulator/game_log.txt"
RUN_DATA_PATH = "C:/Users/rocke/Documents/rpg-simulator/src/data/run_data.json"

def _init():
	g = Path(GAME_LOG_PATH)
	r = Path(RUN_DATA_PATH)

	# the log file must exist before we can parse it
	if not g.exists():
		raise FileNotFoundError(GAME_LOG_PATH)
	if not r.exists():
		raise FileNotFoundError(GAME_LOG_PATH)

	# clear files
	g.open("w")
	r.open("w")
	return

def main():
	_init()
	
if __name__ == "__main__":
	main()