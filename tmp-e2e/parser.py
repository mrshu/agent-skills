import json


def load_config(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return {}


def get_retries(config):
    return config["retries"]
