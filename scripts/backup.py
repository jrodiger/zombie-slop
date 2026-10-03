#!/usr/bin/env python3
"""Archive sources + private Git/LFS + originals into a user-selected backup destination."""
import argparse,datetime,tarfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--destination',type=Path,required=True);p.add_argument('--home',type=Path,default=Path.home()/'Documents/ZombieSlop');a=p.parse_args()
source=Path(__file__).resolve().parents[1];private=source.parent/'zombie-slop-assets';destination=a.destination.expanduser().resolve()
for base in [source,private,a.home.resolve()/'downloads']:
 if destination==base or base in destination.parents:raise SystemExit('Backup destination must be outside the archived folders.')
destination.mkdir(parents=True,exist_ok=True);target=destination/('Zombie-Slop-backup-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.tar.gz')
with tarfile.open(target,'w:gz') as t:
 for base in [source,private,a.home.resolve()/'downloads']:
  if not base.exists():raise SystemExit('Required source missing: '+str(base))
  t.add(base,arcname=base.name)
print(target)
print('Only a copy on another device/service is an off-machine backup. No remote backup is implied.')
