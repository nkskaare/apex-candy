import os
import json
import argparse
import asyncio

from python_sfdx.sfdx import SFDX, loading_bar

def create_temp_sandbox_def(sandbox_name):

    def_path = './config/dev-sandbox-def.json'
    with open(def_path, 'r+') as f:
        sandbox_def = json.load(f)
    
    temp_path = './config/temp-sandbox-def.json'
    with open(temp_path, 'w+') as f:
        sandbox_def['sandboxName'] = sandbox_name
        f.seek(0)
        json.dump(sandbox_def, f, indent=4)
        f.truncate()



async def main(sandbox, sourceorg):

    try:
        print('Creating sandbox...')

        temp_path = './config/temp-sandbox-def.json'

        sfdx = SFDX()
        res = await asyncio.gather(
            sfdx.create_sandbox(sandbox, sourceorg, definition=temp_path),
            loading_bar(sfdx.running)
        )

        os.remove(temp_path)
        print('Sandbox is ready!')
    except Exception as e:
        os.remove(temp_path)
        print('Sandbox creation failed.')
        print('Error message: ' + e)
        return

    try:
        print('Deploying metadata...')
        sfdx = SFDX()
        res = await asyncio.gather(
            sfdx.deploy(sandbox),
            loading_bar(sfdx.running)
        )

        print('Deployment complete!')

    except Exception as e:
        print('Metadata deployment failed.')
        print('Error message: ' + e)
        return


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description='Create new sandbox and load data and settings')
    parser.add_argument('--alias', type=str, help='New sandbox sfdx alias')
    parser.add_argument('--name', type=str, help='New sandbox name')
    parser.add_argument('--sourceorg', type=str,
                        help='Production org or sandbox to clone')

    args = parser.parse_args()


    create_temp_sandbox_def(args.name)

    try:
        asyncio.run(main(args.alias, args.sourceorg))
    except e:
        print(e)


