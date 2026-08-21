#!/usr/bin/env python3
# gds2png.py - GDS-II -> PNG rasterizer. Usage: gds2png.py in.gds out.png [both]
# A pure-Python renderer (no X/qt/klayout) drawing layer-colored polygons.
import struct, sys
from PIL import Image, ImageDraw
from collections import Counter

BOUNDARY=0x08; PATH=0x09; LAYER=0x0D; DATATYPE=0x0E; WIDTH=0x0F; XY=0x10; ENDEL=0x11; ENDLIB=0x04

PAL = {1:(235,120,50),2:(55,160,225),3:(70,225,125),4:(220,70,70),5:(185,95,225),
       6:(240,205,65),7:(100,165,205),8:(165,225,95),9:(210,130,230),10:(90,200,160),
       11:(230,160,80),12:(140,140,255),13:(80,210,220),14:(255,150,150),15:(170,170,90),
       16:(120,170,255),17:(230,90,180),18:(110,200,30),19:(170,120,255),20:(200,200,60),
       40:(60,40,50),41:(90,90,110),44:(110,110,130),45:(60,60,80),49:(70,70,95),
       64:(190,190,160),65:(220,160,90),66:(140,140,140),67:(170,220,120),68:(255,180,80),
       69:(90,190,110),70:(200,200,240),71:(240,240,100),72:(190,100,100),
       76:(160,120,200),79:(130,130,210),81:(120,200,160)}
DCOL=(240,240,240)

def read_records(path):
    recs=[]
    with open(path,'rb') as f:
        while True:
            hdr=f.read(4)
            if not hdr or len(hdr)<4: break
            reclen,rt16=struct.unpack('>HH',hdr)
            if reclen<4 or reclen>1048576: break
            data=f.read(reclen-4)
            recs.append((rt16>>8,data))
            if (rt16>>8)==ENDLIB: break
    return recs

def parse_gds(path, dbu=1000.0):
    polys,paths=[],[]
    recs=read_records(path); i=0; n=len(recs)
    while i<n:
        rtype,data=recs[i]
        if rtype==BOUNDARY:
            lyr=None;pts=None;j=i+1
            while j<n:
                t2,d2=recs[j]
                if t2==LAYER and len(d2)>=2: lyr=struct.unpack('>h',d2[:2])[0]
                elif t2==XY:
                    m=len(d2)//8; pts=[struct.unpack('>ii',d2[k*8:k*8+8]) for k in range(m)]
                elif t2==ENDEL: break
                j+=1
            if lyr is not None and pts and len(pts)>=3:
                if pts[0]==pts[-1]: pts=pts[:-1]
                polys.append((lyr,[(x/dbu,y/dbu) for x,y in pts]))
            i=j+1
        elif rtype==PATH:
            lyr=None;wid=None;pts=None;j=i+1
            while j<n:
                t2,d2=recs[j]
                if t2==LAYER and len(d2)>=2: lyr=struct.unpack('>h',d2[:2])[0]
                elif t2==WIDTH and len(d2)>=4: wid=struct.unpack('>i',d2[:4])[0]/dbu
                elif t2==XY:
                    m=len(d2)//8; pts=[struct.unpack('>ii',d2[k*8:k*8+8]) for k in range(m)]
                elif t2==ENDEL: break
                j+=1
            if lyr is not None and pts and len(pts)>=2:
                paths.append((lyr,wid or 0.2,[(x/dbu,y/dbu) for x,y in pts]))
            i=j+1
        else: i+=1
    return polys,paths

def render(polys,paths,out,w=1600,h=1200,margin=0.02,
           xmin=None,xmax=None,ymin=None,ymax=None):
    xs=[x for _,p in polys for (x,_) in p]; ys=[y for _,p in polys for (_,y) in p]
    if not xs: print("no geometry"); return 0
    if xmin is None: xmin,xmax,ymin,ymax=min(xs),max(xs),min(ys),max(ys)
    dx,dy=(xmax-xmin) or 1,(ymax-ymin) or 1
    x0=xmin-margin*dx;x1=xmax+margin*dx;y0=ymin-margin*dy;y1=ymax+margin*dy
    sx=(w-12)/(x1-x0);sy=(h-12)/(y1-y0)
    img=Image.new('RGB',(w,h),(8,10,18)); d=ImageDraw.Draw(img)
    def T(p): return (int((p[0]-x0)*sx)+6, h-6-int((p[1]-y0)*sy))
    for lyr,wid,pts in sorted(paths,key=lambda t:t[0]):
        p=[T(q) for q in pts]
        if len(p)>=2: d.line(p,fill=PAL.get(lyr,DCOL),width=max(1,int(abs(wid)*sx)))
    for lyr,pts in sorted(polys,key=lambda t:t[0]):
        p=[T(q) for q in pts]
        if len(p)>=3: d.polygon(p,fill=PAL.get(lyr,DCOL))
    img.save(out); return len(polys)

if __name__=="__main__":
    gds=sys.argv[1]; out=sys.argv[2] if len(sys.argv)>2 else "/tmp/layout.png"
    zoom=float(sys.argv[3]) if len(sys.argv)>3 else 0.0
    polys,paths=parse_gds(gds)
    print("polygons:",len(polys),"paths:",len(paths))
    print("layers:",Counter(p[0] for p in polys).most_common(12))
    xs=[x for _,p in polys for (x,_) in p]; ys=[y for _,p in polys for (_,y) in p]
    if zoom and polys:
        cx=(min(xs)+max(xs))/2; cy=(min(ys)+max(ys))/2
        dx=(max(xs)-min(xs))*zoom; dy=(max(ys)-min(ys))*zoom
        render(polys,paths,out,xmin=cx-dx/2,xmax=cx+dx/2,ymin=cy-dy/2,ymax=cy+dy/2)
    else:
        render(polys,paths,out)
    print("WROTE",out)