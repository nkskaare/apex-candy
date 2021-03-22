import asyncio
import json


class SFDX:
    """Simplified API for running sfdx commands asyncronously from python scripts
    """



    def __init__(self):
        self.running = asyncio.Event()

    async def run(self, command, args={}):
        """Run sfdx command and return json result as dict

        Args:
            command (str): Command namespace
            args (dict, optional): Command arguments (flags and values). Defaults to {}.

        Raises:
            Exception: Exception if command fails

        Returns:
            [dict]: command output
        """

        self.running.clear()

        cmd = SFDX.parse_command(command, args)

        proc = await asyncio.create_subprocess_shell(
            cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE)

        stdout, stderr = await proc.communicate()

        if stderr:
            print(stderr)
            raise Exception(
                f'Error "{stderr}" when executing command: "{cmd}"')

        self.running.set()

        return json.loads(stdout.decode().strip())

    @staticmethod
    def parse_command(command, args):
        """Parse input command and args to full sfdx command

        Args:
            command (str): command namespace
            args (dict): command arguments (flags and values)

        Returns:
            [type]: [description]
        """
        full_command = f"sfdx {command}"

        for flag, value in args.items():
            full_command += f' {flag}'
            if value:
                full_command += f' {value}'

        full_command += ' --json'

        return full_command


    async def create_sandbox(self, sandbox, sourceorg, definition="./config/dev-sandbox-def.json", wait=30):
        return await self.run("force:org:create", {"-t": "sandbox", "-u": f"{sourceorg}", "-f":
                                                   f"{definition}", "-a": f"{sandbox}", "-w": f"{wait}"})


    async def deploy(self, username, path="./force-app/"):
        return await self.run("force:source:deploy", {
            "-f": f"{path}", "-u": f"{username}"})


    async def list_orgs(self):
        return await self.run("force:org:list")
    
    async def execute(self, username, path):
        return await self.run("force:apex:execute", {"-u" : f"{username}", "-f" : f"{path}"})

    async def data_import(self, username, path=None, plan=None):
        args = {"-u" : f"{username}"}
        if plan:
            args.update({"-p" : f"{plan}"})
        else if path:
            args.update({"-f" : f"{path}"})
        else:
            raise Exception('Must provide either a data path or plan')

        return await self.run("force:data:tree:import", args)


async def loading_bar(event):
    """Animate loading bar

    Args:
        event (asyncio.Event): Event which determines termination
    """
    animation = [
        "[        ]",
        "[=       ]",
        "[===     ]",
        "[====    ]",
        "[=====   ]",
        "[======  ]",
        "[======= ]",
        "[========]",
        "[ =======]",
        "[  ======]",
        "[   =====]",
        "[    ====]",
        "[     ===]",
        "[      ==]",
        "[       =]",
        "[        ]",
        "[        ]"
    ]

    idx = 0
    while not event.is_set():
        print(animation[idx % len(animation)], end="\r")
        idx += 1
        await asyncio.sleep(.1)
    

