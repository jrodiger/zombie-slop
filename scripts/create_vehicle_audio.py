"""Create or export an original, seamless combustion-engine loop outside public Git."""
import argparse, array, hashlib, json, math, random, shutil, wave
from pathlib import Path

p=argparse.ArgumentParser()
p.add_argument('--assets',type=Path,required=True)
p.add_argument('--home',type=Path,required=True)
p.add_argument('--export-only',action='store_true')
p.add_argument('--replace-existing',action='store_true',help='Explicitly regenerate this original loop; preserve an external backup first.')
a=p.parse_args();private=a.assets.resolve();home=a.home.resolve();public=Path(__file__).resolve().parents[1]
if a.export_only and a.replace_existing:p.error('--export-only cannot replace a checkpoint')
for folder in (private,home):
    if folder==public or public in folder.parents:raise SystemExit('Audio must stay outside public source.')
if home==private or private in home.parents:raise SystemExit('Exports must stay outside private sources.')
folder=private/'neighborhood/audio';path=folder/'vehicle-engine.wav';recipe=folder/'vehicle-engine.json'
if not a.export_only:
    if (path.exists() or recipe.exists()) and not a.replace_existing:raise SystemExit('Existing engine audio protected; use --export-only.')
    params={'rate':22050,'seconds':8,'fundamental':48,'seed':1045,'peak':.55,'source':'Original combustion pulse/harmonic synthesis','generator':'scripts/create_vehicle_audio.py'}
    rng=random.Random(params['seed']);count=params['rate']*params['seconds'];values=[];noise=0;filtered=[]
    for i in range(count):
        noise=.82*noise+.18*rng.uniform(-1,1);filtered.append(noise)
    # Only the stochastic component needs wrapping: the harmonic signal already
    # has an integral number of cycles. Preserve that phase at the loop seam.
    fade=int(params['rate']*.03)
    for i in range(fade):
        alpha=i/(fade-1);filtered[-fade+i]=filtered[-fade+i]*(1-alpha)+filtered[0]*alpha
    for i in range(count):
        t=i/params['rate'];phase=math.tau*params['fundamental']*t
        pulse=(.5+.5*math.sin(phase))**5
        values.append(.36*math.sin(phase)+.2*math.sin(phase*2+.3)+.12*math.sin(phase*3)+.07*math.sin(phase*5)+filtered[i]*(.1+.3*pulse))
    mean=sum(values)/count;peak=max(abs(v-mean) for v in values)
    pcm=array.array('h',(round((v-mean)/peak*params['peak']*32767) for v in values))
    folder.mkdir(parents=True,exist_ok=True)
    with wave.open(str(path),'wb') as f:f.setparams((1,2,params['rate'],0,'NONE','not compressed'));f.writeframes(pcm.tobytes())
    params['sha256']=hashlib.sha256(path.read_bytes()).hexdigest();recipe.write_text(json.dumps(params,indent=2)+'\n')
params=json.loads(recipe.read_text())
assert hashlib.sha256(path.read_bytes()).hexdigest()==params['sha256']
out=home/'generated';out.mkdir(parents=True,exist_ok=True);shutil.copy2(path,out/path.name)
print('Exported unchanged original engine-loop checkpoint.')
