import subprocess


def bash(command):
    try:
        output = subprocess.check_output(
            args=command,
            shell=True,
            stderr=subprocess.PIPE
        )
        print(output)
    except subprocess.CalledProcessError as e:
        print(f'command: {command}')
        print(f'exit code: {e.returncode}')
        print(f'stdout: {e.output.decode(sys.getfilesystemencoding())}')
        print(f'stderr: {e.stderr.decode(sys.getfilesystemencoding())}')
        raise e