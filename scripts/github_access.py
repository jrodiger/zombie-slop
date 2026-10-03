#!/usr/bin/env python3
"""GitHub API helper: secrets stay in memory, never in logs or files."""
import argparse,json,os,subprocess,urllib.request,urllib.error
from pathlib import Path

def call(path, data=None, method=None):
    """Authenticate a GitHub API request without printing or persisting secrets."""
    p=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,timeout=20)
    cred=dict(line.split('=',1) for line in p.stdout.splitlines() if '=' in line)
    cli=Path.home()/'Documents/ZombieSlop/tools/gh'
    candidates=list(cli.rglob('gh')) if cli.exists() else []
    binary=next((x for x in candidates if x.is_file()),None)
    gh=subprocess.run([str(binary),'auth','token'],capture_output=True,text=True,timeout=15) if binary else None
    token=os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN') or cred.get('password') or (gh.stdout.strip() if gh and gh.returncode==0 else None)
    if not token: raise SystemExit('GitHub authentication unavailable; no credentials printed.')
    r=urllib.request.Request('https://api.github.com/'+path,data=json.dumps(data).encode() if data is not None else None,method=method,headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','User-Agent':'ZombieSlop','Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r,timeout=45) as response: return json.load(response)
    except urllib.error.HTTPError as e:
        if e.code==404:return None
        raise SystemExit('GitHub request failed: HTTP '+str(e.code))

def main():
    """Check repository identity and optionally create the authorized private repo."""
    p=argparse.ArgumentParser();p.add_argument('action',choices=['check','create-assets']);a=p.parse_args()
    public=call('repos/jrodiger/zombie-slop')
    print('Public repo:',public['full_name'] if public else 'not accessible')
    asset=call('repos/jrodiger/zombie-slop-assets')
    if asset is None and a.action=='create-assets':
        owner=call('user')
        if not owner or owner.get('login')!='jrodiger':raise SystemExit('Authenticated owner must be jrodiger to create the asset repository.')
        asset=call('user/repos',{'name':'zombie-slop-assets','private':True,'description':'Private editable assets for Zombie Slop. Asset licenses remain separate.'})
    if asset:
        if asset.get('full_name')!='jrodiger/zombie-slop-assets':raise SystemExit('Asset repository identity mismatch.')
        if not asset['private']:raise SystemExit('CONFLICT: asset repository is public; do not upload assets.')
        print('Private asset repo verified:',asset['html_url'])
    else: print('Private asset repo does not yet exist or is inaccessible.')
if __name__=='__main__':main()
