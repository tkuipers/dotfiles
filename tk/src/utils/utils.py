from pathlib import Path
import os
import json
import sys


def load_json(path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        with open(path, 'r') as f:
            return json.load(f)
    else:
        return {}
    
def get_project_root():
    return Path(__file__).parent.parent.parent

def get_app_state_dir():
    return Path.joinpath(get_project_root(), 'app_state/')

def get_profiles_dir():
    return Path.joinpath(get_project_root(), 'profiles/')

def get_profiles_dict():
    return load_json(Path.joinpath(get_app_state_dir(), 'profiles.json'))

def load_module(module):
    dir = get_profiles_dir()
    sys.path.append(str(dir.absolute()))
    sys.path.append(str(get_project_root().absolute()))

    module_path = module

    if module_path in sys.modules:
        return sys.modules[module_path]
    try:
        return __import__(module_path, fromlist=[module])
    except Exception:
        return None