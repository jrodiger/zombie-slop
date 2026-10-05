#!/usr/bin/env python3
"""Build and verify a privately transferred, personally signed Android APK."""
import argparse,hashlib,json,os,shutil,subprocess,secrets
from pathlib import Path
from assemble import outside
from record_build import record as record_export

SOURCE=Path(__file__).resolve().parents[1]
def main():
 """Assemble external assets, configure the installed SDK and sign a demo APK."""
 p=argparse.ArgumentParser()
 p.add_argument('--home',type=Path,default=Path(os.environ.get('ZOMBIE_HOME',Path.home()/'Documents/ZombieSlop')))
 p.add_argument('--assets',type=Path,default=Path(os.environ.get('ZOMBIE_ASSETS',SOURCE.parent/'zombie-slop-assets')))
 p.add_argument('--godot',default=os.environ.get('GODOT'))
 a=p.parse_args();home=a.home.expanduser().resolve();assets=a.assets.expanduser().resolve();outside(home,[SOURCE,assets])
 toolchain=home/'tools/android-toolchain.json'
 installed=json.loads(toolchain.read_text()) if toolchain.is_file() else {}
 java=os.environ.get('JAVA_HOME',installed.get('java',''));sdk=os.environ.get('ANDROID_HOME',installed.get('sdk',''))
 if not java or not sdk:raise SystemExit('Install Java 17 and the Android SDK first; see docs/DEVICES.md. Set JAVA_HOME and ANDROID_HOME.')
 java=Path(java).expanduser().resolve();sdk=Path(sdk).expanduser().resolve()
 godot=a.godot or str(home/'tools/Godot.app/Contents/MacOS/Godot')
 build_tools=sdk/'build-tools/35.0.1';suffix='.bat' if os.name=='nt' else ''
 keytool=java/'bin'/('keytool.exe' if os.name=='nt' else 'keytool')
 apksigner=build_tools/('apksigner'+suffix);aapt=build_tools/('aapt.exe' if os.name=='nt' else 'aapt')
 if not all(x.is_file() for x in [keytool,apksigner,aapt]):raise SystemExit('Missing Java keytool or Android build-tools 35.0.1; see docs/DEVICES.md.')
 env=os.environ.copy();env['JAVA_HOME']=str(java);env['ANDROID_HOME']=str(sdk)
 env['PATH']=str(java/'bin')+os.pathsep+env.get('PATH','')
 subprocess.run(['python3',str(SOURCE/'scripts/check_source.py')],check=True)
 subprocess.run(['python3',str(SOURCE/'scripts/assemble.py'),'--home',str(home),'--assets',str(assets)],check=True)
 setup=home/'tools/android-config';setup.mkdir(parents=True,exist_ok=True)
 (setup/'project.godot').write_text('config_version=5\n[application]\nconfig/name="Zombie Slop Android setup"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
 shutil.copy2(SOURCE/'scripts/configure_android.gd',setup/'configure_android.gd')
 subprocess.run([godot,'--headless','--editor','--path',str(setup),'--script',str(setup/'configure_android.gd')],env=env,check=True)
 keys=home/'tools/android-keys';keys.mkdir(mode=0o700,exist_ok=True)
 keystore=keys/'zombie-slop-demo.keystore';credentials=keys/'demo-signing.json'
 if keystore.exists()!=credentials.exists():raise SystemExit('Incomplete signing checkpoint: restore the existing demo key and credentials; do not replace it.')
 if not credentials.exists():
  signing={'alias':'zombie-slop-demo','password':secrets.token_urlsafe(32)}
  credentials.write_text(json.dumps(signing)+'\n');credentials.chmod(0o600)
  env['ZOMBIE_DEMO_SIGN_PASSWORD']=signing['password']
  try:
   subprocess.run([str(keytool),'-genkeypair','-noprompt','-keystore',str(keystore),'-alias',signing['alias'],'-storepass:env','ZOMBIE_DEMO_SIGN_PASSWORD','-keypass:env','ZOMBIE_DEMO_SIGN_PASSWORD','-keyalg','RSA','-keysize','2048','-validity','10000','-dname','CN=Zombie Slop Personal Demo'],env=env,check=True)
  except Exception:
   if not keystore.exists():credentials.unlink()
   raise
  keystore.chmod(0o600)
 signing=json.loads(credentials.read_text())
 env.update({'GODOT_ANDROID_KEYSTORE_RELEASE_PATH':str(keystore),'GODOT_ANDROID_KEYSTORE_RELEASE_USER':signing['alias'],'GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD':signing['password']})
 runtime=home/'workspace';output=home/'builds/android/Zombie Slop.apk';output.parent.mkdir(parents=True,exist_ok=True)
 subprocess.run([godot,'--headless','--path',str(runtime),'--editor','--import'],env=env,check=True)
 subprocess.run([godot,'--headless','--path',str(runtime),'--export-release','Android',str(output)],env=env,check=True)
 verified=subprocess.check_output([str(apksigner),'verify','--verbose','--print-certs',str(output)],env=env,text=True)
 badging=subprocess.check_output([str(aapt),'dump','badging',str(output)],env=env,text=True)
 if "package: name='com.jrodiger.zombieslop'" not in badging or "native-code: 'arm64-v8a'" not in badging:raise SystemExit('Unexpected APK identity or architecture.')
 # Godot 4.7 launches through an exported activity alias. Older aapt badging
 # omits aliases, so inspect the manifest rather than requiring that summary.
 manifest=subprocess.check_output([str(aapt),'dump','xmltree',str(output),'AndroidManifest.xml'],env=env,text=True)
 if not all(value in manifest for value in ['E: activity-alias','com.godot.game.GodotAppLauncher','android.intent.action.MAIN','android.intent.category.LAUNCHER']):raise SystemExit('Missing Android launcher alias.')
 permissions=subprocess.check_output([str(aapt),'dump','permissions',str(output)],env=env,text=True)
 if 'android.permission.INTERNET' in permissions:raise SystemExit('Personal offline APK unexpectedly requests network permission.')
 record={'apk':str(output),'bytes':output.stat().st_size,'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'paired_revisions':json.loads((runtime/'assembly.json').read_text()),'signature_verification':verified,'package_badging':badging,'launcher_alias_verified':True,'permissions':permissions,'physical_android_tested':False}
 report=home/'verification/device-play';report.mkdir(parents=True,exist_ok=True);(report/'android-export.json').write_text(json.dumps(record,indent=2)+'\n')
 record_export(home,'Android')
 print('Signed APK verified:',output)
if __name__=='__main__':main()
