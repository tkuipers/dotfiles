import enum
import json
import jinja2
import os

class Secrets(object):
    def __init__(self):
        pass
    
    def add(self, secret, value):
        secrets_path = '../res/rc/secrets.json'
        current_secrets = self.__load_json(secrets_path)
        self.__pop_existing(secret, current_secrets)
        current_secrets.append({'name': secret, 'value': value})
        self.__dump_json(secrets_path, current_secrets)
    
    def remove(self, secret):
        secrets_path = '../res/rc/secrets.json'
        current_secrets = self.__load_json(secrets_path)
        self.__pop_existing(secret, current_secrets)
        self.__dump_json(secrets_path, current_secrets)
    
    def __pop_existing(self, secret, current_secrets):
        i_to_pop = None
        for i, val in enumerate(current_secrets):
            if val['name'] == secret:
                i_to_pop = i
                break
        if i_to_pop != None:
            current_secrets.pop(i_to_pop)

    def __load_json(self, json_path):
        if os.path.exists(json_path) and os.path.getsize(json_path) > 0:
            with open(json_path, 'r') as f:
                return json.load(f)
        else:
            return []
    
    def __dump_json(self, json_path, dict):
        if os.path.exists(json_path):
            with open(json_path, 'w') as outfile:
                json.dump(dict, outfile)