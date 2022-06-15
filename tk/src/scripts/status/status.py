from utils.colorprint import prGreen, prRed
from utils.utils import get_profiles_dict


class Status(object):
    def display_status(self):
        all_profiles = get_profiles_dict()
        all_profiles.sort(key = lambda x: not x['active'])
        for profile in all_profiles:
            if profile['active']:
                prGreen(f'* {profile["profile_name"]}')
            else:
                prRed(f'  {profile["profile_name"]}')