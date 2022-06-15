from pathlib import Path
from sys import platform

from utils.utils import get_app_state_dir, get_profiles_dict, load_module
from .rc_builder import RCBuilder
import json

class Install(object):
    def __init__(self):
        self.is_linux = platform == "linux" or platform == "linux2"
        self.__rc_builder = RCBuilder()

    def install(self, profile):
        self.__run_installer(profile)
        self.__change_profile(profile, True)
        self.__rc_builder.build_rc()

    def uninstall(self, profile):
        self.__change_profile(profile, False)
        self.__rc_builder.build_rc()

    def __change_profile(self, profile_name, active):
        all_profiles = get_profiles_dict()
        for profile in all_profiles:
            if profile['profile_name'] == profile_name:
                profile['active'] = active
                with open(Path.joinpath(get_app_state_dir(), 'profiles.json'), 'w') as outfile:
                    json.dump(all_profiles, outfile)
                    return True
        return False
    
    def __run_installer(self, profile):
        cls = load_module(f'{profile}.setup')
        if cls and cls.Setup:
            setup = cls.Setup()
            setup.install()
