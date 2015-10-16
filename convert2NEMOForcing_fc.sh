#!/bin/sh
# Download first: done manually from MARS catalogue
# then this script converts to ORCA025 grid forcing files for NEMO

DATE=20150601g20150630
DATEOUT=y2015m06
#NYR=$(( $YR+1 ))
export SKIP_SAME_TIME=1
# use cdo to mergetime
CDO="cdo -O -t ecmwf -f nc"
# We only need one grid as T and U V grid forcing variables are all in T grid
ORCA025GRDFILE=/lustre/tmp/gierisch/forcing/ORCA025_grid.nc
#AGI ORCA025GRDFILE=/lustre/tmp/uotilap/ORCA025LIM3Byoung/ORCA025-N401_1d_20050501_20050531_icemod.nc
#cdo genbil,${ORCA025GRDFILE} 2t_erai_2014.nc /lustre/tmp/gierisch/forcing/ORCA025weights.nc

# 3h variables
#${CDO} mergetime ${DATE}_00.grb ${DATE}_03.grb ${DATE}_3h.nc
${CDO} cat ${DATE}_03.grb ${DATE}_3h.nc
for VAR in T2M D2M U10M V10M SP
do
  ${CDO} selname,${VAR} ${DATE}_3h.nc  ${VAR}_fc_${DATE}.nc
  #${CDO} seldate,${YR}-01-01T03:00:00,${NYR}-01-01T00:00:00 ${VAR}_erai_${YR}.3h.nc ${VAR}_erai_${YR}.nc
  #rm ${VAR}_erai_${YR}.3h.nc
done


# 12h variables
# these are accumulated over 12h so need to divide by 12*3600 to get W m**-2
# but it is enough to use 12h forecasts only for daily means.
for VAR in SSRD STRD
do
  ${CDO} selname,${VAR} ${DATE}_24.grb  ${VAR}_fc_${DATE}_org.nc
  ${CDO} divc,86400 -shifttime,-12hour ${VAR}_fc_${DATE}_org.nc ${VAR}_fc_${DATE}.nc
  #${CDO} seldate,${YR}-01-01T00:00:00,${NYR}-01-01T00:00:00 ${VAR}_erai_${YR}.1d.nc ${VAR}_erai_${YR}.nc
  #rm ${VAR}_erai_${YR}.1d.nc
done
# precip converted from m -> kg/(m**2 s) and  are accumulated over 12h so need to divide by 12*3600/1000
for VAR in TP SF
do
  ${CDO} selname,${VAR} ${DATE}_24.grb  ${VAR}_fc_${DATE}_org.nc
  ${CDO} divc,86.4 -shifttime,-12hour ${VAR}_fc_${DATE}_org.nc ${VAR}_fc_${DATE}.nc
  #${CDO} seldate,${YR}-01-01T00:00:00,${NYR}-01-01T00:00:00 ${VAR}_erai_${YR}.1d.nc ${VAR}_erai_${YR}.nc
  #rm ${VAR}_erai_${YR}.1d.nc
done

# t2m, d2m, sp
# change units from K to C
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,T2M,t2m T2M_fc_${DATE}.nc t2m_${DATEOUT}.nc
#${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,D2M,d2m 2d_erai_${YR}.nc d2m_ERAINT-ORCA025_${YR}.nc
#${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,SP,sp sp_erai_${YR}.nc sp_ERAINT-ORCA025_${YR}.nc
python d2m2spechum_fc.py ${DATE}
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc q2m_fc_${DATE}.nc q2m_${DATEOUT}.nc
# lwrad
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,STRD,lwrad STRD_fc_${DATE}.nc lwrad_${DATEOUT}.nc

# swrd
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,SSRD,swrd SSRD_fc_${DATE}.nc swrd_${DATEOUT}.nc

# snow
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,SF,snow SF_fc_${DATE}.nc snow_${DATEOUT}.nc

# precip, assume precip contains snow but liquid is still tp, not tp-sf
#${CDO} sub tp_erai_${YR}.nc sf_erai_${YR}.nc prcmsf_erai_${YR}.nc
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,TP,precip TP_fc_${DATE}.nc precip_${DATEOUT}.nc

# u10m v10m
# rotation?
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,U10M,u10m U10M_fc_${DATE}.nc u10m_${DATEOUT}.nc
${CDO} remap,${ORCA025GRDFILE},/lustre/tmp/gierisch/forcing/ORCA025weights.nc -chname,V10M,v10m V10M_fc_${DATE}.nc v10m_${DATEOUT}.nc

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
