#!/bin/env/python
"""
Calculate specific humidity from air temperature, dew point temperature
and pressure.
"""

import sys
import numpy as np

import netCDF4 as nc

def spechum(T,p):
    # Rdry, Rvap = 287., 461. # JK**-1kg**-1
    r = 287./461.
    eps  = np.zeros(T.shape)
    pidx = np.where(T>273.15)
    nidx = np.where(T<=273.15)
    eps[pidx] = 611.21*np.exp(17.502*(T[pidx]-273.16)/(T[pidx]-32.19))
    eps[nidx] = 611.21*np.exp(22.587*(T[nidx]-273.16)/(T[nidx]+20.70))
    q = (r*eps)/(p-(1-r)*eps)
    return q

if __name__=="__main__":
    year = sys.argv[1]
    fnd = "D2M_fc_%s.nc" % year
    fnp = "SP_fc_%s.nc" % year
    fnq = "q2m_fc_%s.nc" % year
    fpd = nc.Dataset(fnd)
    fpp = nc.Dataset(fnp)
    fpq = nc.Dataset(fnq,'w')
    for attr in fpd.ncattrs():
        setattr(fpq,attr,getattr(fpd,attr))
    setattr(fpq,'history',getattr(fpd,'history')+'. q2m calculated from tdew by d2m2spechum.py.')
    fpq.createDimension('time',None)
    fpq.createDimension('lon',len(fpd.dimensions['lon']))
    fpq.createDimension('lat',len(fpd.dimensions['lat']))
    fpq.createVariable('time','f8',('time',))
    fpq.createVariable('lat','f4',('lat',))
    fpq.createVariable('lon','f4',('lon',))
    fpq.createVariable('q2m','f4',('time','lat','lon',))
    for vname in ['time','lon','lat']:
        if vname in ['lon','lat','time']:
            for attr in fpd.variables[vname].ncattrs():
                setattr(fpq.variables[vname],attr,getattr(fpd.variables[vname],attr))
        if vname in ['lon','lat']:
            fpq.variables[vname][:] = fpd.variables[vname][:]
    setattr(fpq.variables['q2m'],'units','g/g')
    setattr(fpq.variables['q2m'],'long_name','2 m specific humidity')
    time = fpd.variables['time']
    d2m = fpd.variables['D2M']
    sp  = fpp.variables['SP']
    for i,t in enumerate(time[:]):
        q2m = spechum(d2m[i],sp[i])
        fpq.variables['time'][i] = t
        fpq.variables['q2m'][i] = q2m
    for fp in [fpd,fpp,fpq]:
        fp.close()
    print "Finnished!"
