from sys import platform
import json
import jinja2

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
        loader = jinja2.FileSystemLoader(f'../res/rc/company/{company_name}')
        env = jinja2.Environment(loader=loader)
        env.filters['json'] = json.dumps
        template = env.get_template('alias.json')
        print(
            template.render({
                'service_name': 'worker',
                'context_name': 'googlesellerratings',
                'ARTERYS_MIDDLE_ROOT': "hello"
            })
        )
        print("Installing on mac")
        print(company_name)
        print(dev_env)



    