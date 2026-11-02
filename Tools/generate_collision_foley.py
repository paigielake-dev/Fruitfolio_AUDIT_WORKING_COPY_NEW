#!/usr/bin/env python3
"""Original deterministic, sample-free soft water/wood Foley for Fruitfolio.
Source and generated assets: CC0-1.0. No external recordings or sampled material.
"""
import hashlib, json, math, random, struct, wave
from pathlib import Path
RATE=48000
ROOT=Path(__file__).resolve().parents[1]


def filtered_noise(count, seed, low=350, high=4500, periodic=False):
    rng=random.Random(seed); white=[rng.uniform(-1,1) for _ in range(count)]
    a=1-math.exp(-2*math.pi*high/RATE); b=1-math.exp(-2*math.pi*low/RATE)
    hi=lo=0.0; result=[]
    for turn in range(2 if periodic else 1):
        result=[]
        for x in white:
            hi+=a*(x-hi); lo+=b*(x-lo); result.append(hi-lo)
    return result


def write(name, values, peak, note):
    maximum=max(abs(x) for x in values) or 1
    values=[x*peak/maximum for x in values]
    pcm=b''.join(struct.pack('<h',round(max(-1,min(1,x))*32767)) for x in values)
    folder=ROOT/'Fruitfolio/Assets.xcassets/Audio'/f'{name}.dataset';folder.mkdir(parents=True,exist_ok=True)
    path=folder/(name+'.wav')
    with wave.open(str(path),'wb') as output:
        output.setnchannels(1);output.setsampwidth(2);output.setframerate(RATE);output.writeframes(pcm)
    (folder/'Contents.json').write_text(json.dumps({'data':[{'filename':path.name,'idiom':'universal'}],'info':{'author':'xcode','version':1}},indent=2)+'\n')
    return dict(asset=name,file=str(path.relative_to(ROOT)),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),sampleRate=RATE,frames=len(values),durationSeconds=len(values)/RATE,peak=peak,rms=math.sqrt(sum(x*x for x in values)/len(values)),description=note)


def main():
    output=[]
    n=round(.44*RATE);noise=filtered_noise(n,1102);entry=[]
    for i,x in enumerate(noise):
        t=i/RATE; envelope=(1-math.exp(-t/.003))*math.exp(-t/.115)*min(1,(.44-t)/.075)
        bubbles=0.0
        for onset,frequency,gain in [(.008,1050,.12),(.034,730,.09),(.075,580,.07),(.12,420,.04)]:
            d=t-onset
            if d>=0:bubbles+=gain*math.sin(2*math.pi*frequency*math.log1p(4*d)/4)*math.exp(-d/.035)*(1-math.exp(-d/.002))
        entry.append(x*envelope+bubbles)
    output.append(write('audio_puddle_entry',entry,.48,'Soft short filtered-water entry with small decaying bubble resonances; original synthesis, not a field recording.'))
    duration=1.8;n=round(duration*RATE);noise=filtered_noise(n,1103,low=180,high=3200,periodic=True);movement=[]
    for i,x in enumerate(noise):
        t=i/RATE; swell=.62+.18*math.sin(2*math.pi*t/duration)+.10*math.cos(6*math.pi*t/duration)
        bubbles=0.0
        for onset,freq in [(.18,510),(.65,670),(1.05,430),(1.46,780)]:
            d=(t-onset)%duration
            if d<.16:bubbles+=.035*math.sin(2*math.pi*freq*math.log1p(5*d)/5)*math.exp(-d/.025)*math.sin(math.pi*d/.16)**2
        movement.append(x*swell+bubbles)
    output.append(write('audio_puddle_movement',movement,.30,'Gentle continuous water motion; periodic filtered noise and wrapped micro-bubbles for gapless looping.'))
    n=round(.24*RATE);noise=filtered_noise(n,1104,low=650,high=3800);impact=[]
    for i,x in enumerate(noise):
        t=i/RATE; attack=1-math.exp(-t/.0018); tail=min(1,(.24-t)/.055)
        wood=sum(gain*math.sin(2*math.pi*f*t)*math.exp(-t/decay) for f,gain,decay in [(185,.8,.045),(430,.32,.023),(920,.12,.012)])
        impact.append((wood+x*.35*math.exp(-t/.011))*attack*tail)
    output.append(write('audio_branch_impact',impact,.42,'Soft damped wooden tap/rustle, without a harsh high-frequency click; original synthesis.'))
    provenance=dict(license='CC0-1.0',licenseURL='https://creativecommons.org/publicdomain/zero/1.0/',externalSamplesUsed=False,generator='Tools/generate_collision_foley.py',seedPolicy='Fixed explicit seeds1102–1104; reproducible PCM',audibleQualityAcceptance='NOT VERIFIED until listening/runtime review; waveform statistics are not perceptual approval',assets=output)
    (ROOT/'Delivery/CollisionAudioAssetProvenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
    print(json.dumps(output,indent=2))

if __name__=='__main__':main()
