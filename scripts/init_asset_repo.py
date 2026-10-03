#!/usr/bin/env python3
import argparse,os,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--path',type=Path,required=True);p.add_argument('--lfs',type=Path,required=True);a=p.parse_args()
root=a.path.expanduser().resolve();root.mkdir(parents=True,exist_ok=True)
env=os.environ.copy();env['PATH']=str(a.lfs.parent)+os.pathsep+env['PATH']
def git(*args):return subprocess.run(['git','-C',str(root),*args],env=env,check=True)
if not (root/'.git').exists():git('init','-b','main')
remote=subprocess.run(['git','-C',str(root),'remote','get-url','origin'],text=True,capture_output=True)
if remote.returncode==0 and remote.stdout.strip() not in ('https://github.com/jrodiger/zombie-slop-assets.git','git@github.com:jrodiger/zombie-slop-assets.git'):raise SystemExit('Existing asset remote identity mismatch.')
git('lfs','install','--local')
if not (root/'.gitattributes').exists():
 (root/'.gitattributes').write_text('*.blend filter=lfs diff=lfs merge=lfs -text\n*.png filter=lfs diff=lfs merge=lfs -text\n*.wav filter=lfs diff=lfs merge=lfs -text\n*.glb filter=lfs diff=lfs merge=lfs -text\n')
if not (root/'.gitignore').exists():(root/'.gitignore').write_text('exports/\n.godot/\n*.blend1\n*.blend2\n.DS_Store\n')
if not (root/'README.md').exists():
 (root/'README.md').write_text('# Zombie Slop private assets\n\nEditable original sources and recipe parameters. No MIT license is imposed on third-party assets. Original project assets: copyright Jonathan Rodiger, all rights reserved. Unmodified downloads live separately. Exported GLBs are reproducible and excluded. Git LFS is configured before asset commits. Remote upload requires verified private visibility. No remote backup exists until commits AND LFS objects are pushed.\n')
status=subprocess.check_output(['git','-C',str(root),'status','--porcelain'],text=True)
if status:
 git('add','.gitattributes','.gitignore','README.md');git('commit','-m','Initialize protected asset workspace before modeling')
print('Asset workspace:',root)
