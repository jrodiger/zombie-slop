#!/usr/bin/env python3
"""Prepare verified complete personal transfer packages outside Git."""
import argparse,hashlib,json,os,shutil,stat,zipfile
from pathlib import Path
from assemble import outside
SOURCE=Path(__file__).resolve().parents[1]
def main():
 """Require matching clean exports and package the APK and native Linux pair."""
 p=argparse.ArgumentParser();p.add_argument('--home',type=Path,default=Path(os.environ.get('ZOMBIE_HOME',Path.home()/'Documents/ZombieSlop')));p.add_argument('--assets',type=Path,default=Path(os.environ.get('ZOMBIE_ASSETS',SOURCE.parent/'zombie-slop-assets')));a=p.parse_args();home=a.home.expanduser().resolve();outside(home,[SOURCE,a.assets.expanduser().resolve()])
 records=[json.loads((home/'builds/build-records'/name).read_text()) for name in ['Android.json','Linux.json']]
 if any(d['source_dirty'] for d in records) or records[0]['paired_revisions']!=records[1]['paired_revisions']:raise SystemExit('Rebuild Android and Linux from matching clean source/asset checkpoints before packaging.')
 for d in records:
  for name,sha in d['file_sha256'].items():
   path=home/name
   if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest()!=sha:raise SystemExit('Stale export: '+name)
 linux=home/'builds/cross-platform/linux';binary=linux/'Zombie Slop.x86_64';pck=linux/'Zombie Slop.pck';apk=home/'builds/android/Zombie Slop.apk'
 verification=json.loads((home/'verification/device-play/android-export.json').read_text())
 if verification.get('signature_verified') is not True or verification.get('sha256')!=hashlib.sha256(apk.read_bytes()).hexdigest() or verification.get('paired_revisions')!=records[0]['paired_revisions']:raise SystemExit('APK lacks matching successful signature verification; rebuild with build_android.py.')
 if binary.read_bytes()[:4]!=b'\x7fELF' or pck.read_bytes()[:4]!=b'GDPC':raise SystemExit('Missing native Linux executable or Godot pack.')
 output=home/'builds/transfers';output.mkdir(parents=True,exist_ok=True)
 target=output/'Zombie Slop - Steam Deck.zip';temp=target.with_suffix('.zip.tmp');prefix='Zombie Slop/'
 launcher='#!/bin/sh\nset -eu\ncd -- "$(dirname -- "$0")"\nexec "./Zombie Slop.x86_64" "$@"\n'
 with zipfile.ZipFile(temp,'w',zipfile.ZIP_DEFLATED) as z:
  for file in [binary,pck]:
   info=zipfile.ZipInfo(prefix+file.name);info.create_system=3;info.external_attr=(stat.S_IFREG|(0o755 if file==binary else 0o644))<<16;info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,file.read_bytes())
  info=zipfile.ZipInfo(prefix+'Launch Zombie Slop.sh');info.create_system=3;info.external_attr=(stat.S_IFREG|0o755)<<16;info.compress_type=zipfile.ZIP_DEFLATED;z.writestr(info,launcher)
  z.write(SOURCE/'docs/DEVICES.md',prefix+'README.md')
 os.replace(temp,target)
 copied=output/apk.name;temp=copied.with_suffix('.apk.tmp');shutil.copy2(apk,temp);os.replace(temp,copied)
 shutil.copy2(SOURCE/'docs/DEVICES.md',output/'README.md')
 files={str(f.relative_to(home)):hashlib.sha256(f.read_bytes()).hexdigest() for f in [target,copied,output/'README.md']}
 for f in [target,copied]:f.with_name(f.name+'.sha256').write_text(files[str(f.relative_to(home))]+'  '+f.name+'\n')
 report={'paired_revisions':records[0]['paired_revisions'],'file_sha256':files,'uploaded_or_published':False,'physical_devices_tested':False}
 (home/'verification/device-play/transfer-packages.json').write_text(json.dumps(report,indent=2)+'\n');print('Personal transfer packages:',output)
if __name__=='__main__':main()
