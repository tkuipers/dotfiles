import json
from pathlib import Path
import jinja2
import os
import sys
from utils.utils import get_profiles_dict, get_profiles_dir, get_app_state_dir, load_json

class RCBuilder(object):
    def build_rc(self):
        active_profiles = self.__load_profiles()
        env_vars = []
        source = []
        alias = []
        shortcuts = []

        for profile in active_profiles:
            folder = Path.joinpath(get_profiles_dir(), profile["profile_name"])
            env_vars += self.__load_template("env_vars", folder)
            source += self.__load_template("sources", folder)
            alias += self.__load_template("alias", folder)
            shortcuts += self.__load_template("shortcuts", folder)

        output = self.__render_head() + self.__render_envs(env_vars) + self.__render_source(source) + self.__render_alias(alias) + self.__render_shortcuts(shortcuts)

        print(output)

    def __load_profiles(self):
        all_profiles = get_profiles_dict()
        active_profiles = [profile for profile in all_profiles if profile['active'] == True]
        return active_profiles
    
    def __load_template(self, file, folder):
        if os.path.exists(os.path.join(folder, f'{file}.json')) and os.path.getsize(os.path.join(folder, f'{file}.json')) > 0:
            loader = jinja2.FileSystemLoader(folder)
            env = jinja2.Environment(loader=loader)
            env.filters['json'] = json.dumps
            template = env.get_template(f'{file}.json')
            render_vars = load_json(os.path.join(folder, "tk_vars.json"))
            return json.loads(template.render(render_vars))
        else:
            return []
    
    def __render_head(self):
        return "#!/usr/bin/env bash\nshopt -s histappend\n. ~/.tk/env"

    def __render_envs(self, envs):
        output_string = "# Env Vars\n"
        for env in envs:
            output_string += f'export {env["name"]}="{env["value"]}"\n'
        return output_string + "\n"

    def __render_source(self, sources):
        output_string = "# Source other files\n"
        for source in sources:
            output_string += f'if [[ -f  {source}  ]]\nthen\n\t. {source}\nfi\n\n'
        return output_string + "\n"

    def __render_alias(self, aliases):
        output_string = "# Alias\n"
        for alias in aliases:
            output_string += f'alias {alias["alias"]}="{alias["command"]}"\n'
        return output_string + "\n"

    def __render_shortcuts(self, shortcuts):
        output_string = "# Shortcuts\nif [[ $- == *i* ]]; then\n"
        for shortcut in shortcuts:
            output_string += f'\tbind "{shortcut["shortcut"]}":"{shortcut["command"]}"\n'
        output_string += "fi\n"
        return output_string