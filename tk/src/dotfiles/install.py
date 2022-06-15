from sys import platform
import json
import jinja2
import os

class Install(object):
    def __init__(self):
        self.is_linux = platform == "linux" or platform == "linux2"

    def install(self, company_name = None, dev_env = None):
        if self.is_linux:
            self.__linux_install(company_name, dev_env)
        else:
            self.__mac_install(company_name, dev_env)

    def __linux_install(self, company_name, dev_env):
        print("Installing on linux")
        print(company_name)
        print(dev_env)

    def __mac_install(self, company_name, dev_env):
        to_load = ['../res/rc/default']
        if company_name:
            to_load += [f'../res/rc/company/{company_name}']
        if dev_env:
            to_load += [f'../res/rc/dev_env/{dev_env}']
        env_vars = []
        source = []
        alias = []
        shortcuts = []

        for folder in to_load:
            env_vars += self.__load_template("env_vars", folder)
            source += self.__load_template("sources", folder)
            alias += self.__load_template("alias", folder)
            shortcuts += self.__load_template("shortcuts", folder)

        output = self.__render_head() + self.__render_envs(env_vars) + self.__render_source(source) + self.__render_alias(alias) + self.__render_shortcuts(shortcuts)
        print(output)

    def __load_template(self, file, folder):
        if os.path.exists(os.path.join(folder, f'{file}.json')) and os.path.getsize(os.path.join(folder, f'{file}.json')) > 0:
            loader = jinja2.FileSystemLoader(folder)
            env = jinja2.Environment(loader=loader)
            env.filters['json'] = json.dumps
            template = env.get_template(f'{file}.json')
            render_vars = self.__load_json(os.path.join(folder, "tk_vars.json"))
            return json.loads(template.render(render_vars))
        else:
            return []
    
    def __load_json(self, json_path):
        if os.path.exists(json_path) and os.path.getsize(json_path) > 0:
            with open(json_path, 'r') as f:
                return json.load(f)
        else:
            return {}
    
    def __render_head(self):
        return "#!/usr/bin/env bash\nshopt -s histappend\n"

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