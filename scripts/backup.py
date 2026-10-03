#!/usr/bin/env python3
"""Archive sources + private Git/LFS + originals into a user-selected backup destination."""
import argparse,datetime,tarfile,subprocess
from pathlib import Path
source=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--destination',type=Path,required=True);p.add_argument('--home',type=Path,default=Path.home()/'Documents/ZombieSlop');p.add_argument('--assets',type=Path,default=source.parent/'zombie-slop-assets');a=p.parse_args()
private=a.assets.expanduser().resolve();destination=a.destination.expanduser().resolve()
remote=subprocess.check_output(['git','-C',str(private),'remote','get-url','origin'],text=True).strip()
if remote not in ('https://github.com/jrodiger/zombie-slop-assets.git','git@github.com:jrodiger/zombie-slop-assets.git'):raise SystemExit('Asset repository identity mismatch; backup refused.')
for base in [source,private,a.home.resolve()/'downloads']:
 if destination==base or base in destination.parents:raise SystemExit('Backup destination must be outside the archived folders.')
destination.mkdir(parents=True,exist_ok=True);target=destination/('Zombie-Slop-backup-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.tar.gz')
with tarfile.open(target,'w:gz') as t:
 for base in [source,private,a.home.resolve()/'downloads']:
  if not base.exists():raise SystemExit('Required source missing: '+str(base))
  t.add(base,arcname=base.name)
print(target)
print('Only a copy on another device/service is an off-machine backup. No remote backup is implied.')
