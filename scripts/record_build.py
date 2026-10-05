#!/usr/bin/env python3
"""Record a platform export's paired sources and exact external build hashes."""
import argparse,hashlib,json,subprocess
from pathlib import Path
from assemble import asset_fingerprint
SOURCE=Path(__file__).resolve().parents[1]
def record(home,platform):
 """Fingerprint outputs for packaging; record uncommitted source explicitly."""
 locations={'macOS':home/'builds/Zombie Slop.app','Linux':home/'builds/cross-platform/linux','Windows':home/'builds/cross-platform/windows','Android':home/'builds/android'}
 folder=locations[platform]
 paths=sorted(p for p in folder.rglob('*') if p.is_file())
 if not paths:raise SystemExit('No exported files for '+platform)
 paired=json.loads((home/'workspace/assembly.json').read_text())
 if paired.get('asset_sha256')!=asset_fingerprint(home/'workspace/assets'):raise SystemExit('Assembled assets changed; reassemble before recording an export.')
 current=subprocess.check_output(['git','-C',str(SOURCE),'rev-parse','HEAD'],text=True).strip()
 if paired['code_commit']!=current:raise SystemExit('Runtime source is stale; assemble this checkout before recording an export.')
 diff=subprocess.check_output(['git','-C',str(SOURCE),'diff','HEAD','--binary'])
 untracked=subprocess.check_output(['git','-C',str(SOURCE),'ls-files','--others','--exclude-standard'],text=True)
 result={'platform':platform,'paired_revisions':paired,'source_dirty':bool(diff or untracked),'file_sha256':{str(p.relative_to(home)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}}
 target=home/'builds/build-records'/str(platform+'.json');target.parent.mkdir(parents=True,exist_ok=True);target.write_text(json.dumps(result,indent=2)+'\n');return result
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--home',type=Path,required=True);p.add_argument('--platform',choices=['macOS','Linux','Windows','Android'],required=True);a=p.parse_args();record(a.home.expanduser().resolve(),a.platform)
