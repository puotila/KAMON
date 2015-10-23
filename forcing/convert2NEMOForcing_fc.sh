#!/bin/sh
# Download first: done manually from MARS catalogue
# then this script converts to ORCA025 grid forcing files for NEMO


YEAR=2015
MONTH=06
DATADIR=from_ecaccess
PRFX=agi_

# end of user changable part
################################################

MONTHp1=`printf %02d $(($MONTH + 1 ))`
DATE=${YEAR}${MONTH}01-${YEAR}${MONTHp1}01
DATEOUT=y${YEAR}m${MONTH}
echo $DATE $DATEOUT

export SKIP_SAME_TIME=1

# use cdo to mergetime
CDO="cdo -O -t ecmwf -f nc"

# We only need one grid as T and U V grid forcing variables are all in T grid
ORCA025GRDFILE=/lustre/tmp/gierisch/forcing/ORCA025_grid.nc
ORCA025WEIGHTFILE=/lustre/tmp/gierisch/forcing/ORCA025weights.nc
#AGI ORCA025GRDFILE=/lustre/tmp/uotilap/ORCA025LIM3Byoung/ORCA025-N401_1d_20050501_20050531_icemod.nc
#cdo genbil,${ORCA025GRDFILE} 2t_erai_2014.nc /lustre/tmp/gierisch/forcing/ORCA025weights.nc

# 3h variables
#${CDO} mergetime ${DATE}_00.grb ${DATE}_03.grb ${DATE}_3h.nc
${CDO} cat ${DATADIR}/${PRFX}${DATE}_03.grb ${DATE}_3h.nc
for VAR in T2M D2M U10M V10M SP
do
  ${CDO} selname,${VAR} ${DATE}_3h.nc  ${VAR}_fc_${DATE}_tmp.nc
  ${CDO} seldate,${YEAR}-${MONTH}-01T00:00:00,${YEAR}-${MONTHp1}-01T00:00:00 ${VAR}_fc_${DATE}_tmp.nc ${VAR}_fc_${DATE}.nc 
  rm ${VAR}_fc_${DATE}_tmp.nc
done


# 12h variables
# these are accumulated over 12h so need to divide by 12*3600 to get W m**-2
# but it is enough to use 12h forecasts only for daily means.
for VAR in SSRD STRD
do
  ${CDO} selname,${VAR} ${DATADIR}/${PRFX}${DATE}_24.grb  ${VAR}_fc_${DATE}_org.nc
  ${CDO} divc,86400 -shifttime,-12hour ${VAR}_fc_${DATE}_org.nc ${VAR}_fc_${DATE}_tmp.nc
  ${CDO} seldate,${YEAR}-${MONTH}-01T00:00:00,${YEAR}-${MONTHp1}-01T12:00:00 ${VAR}_fc_${DATE}_tmp.nc ${VAR}_fc_${DATE}.nc
  rm ${VAR}_fc_${DATE}_tmp.nc
done

# precip converted from m -> kg/(m**2 s) and  are accumulated over 12h so need to divide by 12*3600/1000
for VAR in TP SF
do
  ${CDO} selname,${VAR} ${DATADIR}/${PRFX}${DATE}_24.grb  ${VAR}_fc_${DATE}_org.nc
  ${CDO} divc,86.4 -shifttime,-12hour ${VAR}_fc_${DATE}_org.nc ${VAR}_fc_${DATE}_tmp.nc
  ${CDO} seldate,${YEAR}-${MONTH}-01T00:00:00,${YEAR}-${MONTHp1}-01T12:00:00 ${VAR}_fc_${DATE}_tmp.nc ${VAR}_fc_${DATE}.nc
  rm ${VAR}_fc_${DATE}_tmp.nc
done

# t2m, d2m, sp
# change units from K to C
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,T2M,t2m T2M_fc_${DATE}.nc t2m_${DATEOUT}.nc
#${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,D2M,d2m 2d_erai_${YR}.nc d2m_ERAINT-ORCA025_${YR}.nc
#${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,SP,sp sp_erai_${YR}.nc sp_ERAINT-ORCA025_${YR}.nc
python d2m2spechum_fc.py ${DATE}
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} q2m_fc_${DATE}.nc q2m_${DATEOUT}.nc
# lwrad
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,STRD,lwrad STRD_fc_${DATE}.nc lwrad_${DATEOUT}.nc

# swrd
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,SSRD,swrd SSRD_fc_${DATE}.nc swrd_${DATEOUT}.nc

# snow
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,SF,snow SF_fc_${DATE}.nc snow_${DATEOUT}.nc

# precip, assume precip contains snow but liquid is still tp, not tp-sf
#${CDO} sub tp_erai_${YR}.nc sf_erai_${YR}.nc prcmsf_erai_${YR}.nc
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,TP,precip TP_fc_${DATE}.nc precip_${DATEOUT}.nc

# u10m v10m
# rotation?
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,U10M,u10m U10M_fc_${DATE}.nc u10m_${DATEOUT}.nc
${CDO} remap,${ORCA025GRDFILE},${ORCA025WEIGHTFILE} -chname,V10M,v10m V10M_fc_${DATE}.nc v10m_${DATEOUT}.nc

# clean up
for VAR in TP SF SSRD STRD T2M D2M U10M V10M SP
do
  rm ${VAR}_fc_${DATE}.nc 
done
for VAR in TP SF SSRD STRD 
do
  rm ${VAR}_fc_${DATE}_org.nc 
done
rm q2m_fc_${DATE}.nc ${DATE}_3h.nc
