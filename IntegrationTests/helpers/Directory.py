import os
import shutil
import tempfile


class Directory:
    @staticmethod
    def make_temporary(remove_automatically: bool = True) -> 'Directory':
        return Directory(
            path=tempfile.mkdtemp(),
            remove_automatically=remove_automatically
        )

    def __init__(self, path: str, remove_automatically: bool = False):
        self.path = path
        self.remove_automatically = remove_automatically

    def __del__(self):
        if self.remove_automatically:
            shutil.rmtree(self.path)

    def make_sub_directory(self, path: str) -> 'Directory':
        sub_dir_path = os.path.join(self.path, path)
        os.makedirs(sub_dir_path)
        return Directory(path=sub_dir_path)

    def sub_path(self, path: str) -> str:
        return os.path.join(self.path, path)