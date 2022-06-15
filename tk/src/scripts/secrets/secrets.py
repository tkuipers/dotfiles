import enum
import json
from pathlib import Path
from utils.utils import get_app_state_dir, load_json
import jinja2
import os
import keyring

class Secrets(object):
    def __init__(self):
        self.secrets_path = Path.joinpath(get_app_state_dir(),'secrets.json')

    def add(self, profile, secret, value):
        current_secrets = load_json(self.secrets_path)
        if current_secrets == {}:
            current_secrets = []
        self.__pop_existing(profile, secret, current_secrets)
        current_secrets.append({'profile': profile, 'name': secret})
        print(current_secrets)
        self.__dump_json(self.secrets_path, current_secrets)
        keyring.set_password("tk", secret, value)
    
    def remove(self, profile, secret):
        current_secrets = load_json(self.secrets_path)
        self.__pop_existing(profile, secret, current_secrets)
        self.__dump_json(self.secrets_path, current_secrets)
        try:
            keyring.delete_password("tk", secret)
        except Exception:
            return

    def check(self, profile, secret_name):
        current_secrets = load_json(self.secrets_path)
        current_secrets = [secret for secret in current_secrets if secret['profile'] == profile and secret['name'] == secret_name]
        print(keyring.get_password("tk", current_secrets[0]['name']))

    def dump(self, profile):
        current_secrets = load_json(self.secrets_path)
        current_secrets = [secret for secret in current_secrets if secret['profile'] == profile]
        out = []
        for secret in current_secrets:
            out.append((secret['name'], keyring.get_password("tk", secret['name'])))
        return out
    
    def __pop_existing(self, profile, secret, current_secrets):
        i_to_pop = None
        for i, val in enumerate(current_secrets):
            if val['name'] == secret and val['profile'] == profile:
                i_to_pop = i
                break
        if i_to_pop != None:
            current_secrets.pop(i_to_pop)
    
    def __dump_json(self, json_path, dict):
        if os.path.exists(json_path):
            with open(json_path, 'w') as outfile:
                json.dump(dict, outfile)

    