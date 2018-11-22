import subprocess
import sys
from typing import Union
from typing import List

def bash(command: Union[str, List[str]], current_directory: str = None) -> None:
    try:
        output = subprocess.check_output(
            cwd=current_directory,
            args=command,
            shell=type(command) is str,
            stderr=subprocess.PIPE
        )
        print(output)
    except subprocess.CalledProcessError as e:
        print(f'command: {command}')
        print(f'exit code: {e.returncode}')
        print(f'stdout: {e.output.decode(sys.getfilesystemencoding())}')
        print(f'stderr: {e.stderr.decode(sys.getfilesystemencoding())}')
        raise e