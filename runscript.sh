#!/usr/bin/env bash
#PBS -N NEMO36
#PBS -q workq
#PBS -l mppwidth=170
#PBS -l mppnppn=20
#PBS -l mppdepth=1
#PBS -l walltime=48:00:00

set -ue

cd $PBS_O_WORKDIR

# librunscript defines some helper functions
source ./librunscript.sh

# =============================================================================
# *** BEGIN User configuration
# =============================================================================

# -----------------------------------------------------------------------------
# *** General configuration
# -----------------------------------------------------------------------------

# Component configuration
# (for syntax of the $config variable, see librunscript.sh)
#config="nemo lim3 xios:attached"
config="nemo lim3 xios:detached"

# Experiment name (exactly 4 letters!)
exp_name=ei5a

# Simulation start and end date. Use any (reasonable) syntax you want.
run_start_date="2002-01-04"
#run_end_date="${run_start_date} + 10 years"
run_end_date="2015-06-30"

# Set $force_run_from_scratch to 'true' if you want to force this run to start
# from scratch, possibly ignoring any restart files present in the run
# directory. Leave set to 'false' otherwise.
# NOTE: If set to 'true' the run directory $run_dir is cleaned!
force_run_from_scratch=false

# Resolution
nem_grid=ORCA025L75

# NEMO forcing data set
nem_forcing_set=ERAINT-ORCA025

# Restart frequency. Use any (reasonable) number and time unit you want.
# For runs without restart, leave this variable empty
rst_freq="1 month"

# Number of restart legs to be run in one go
run_num_legs=49

# Directories
start_dir=${PWD}
ctrl_file_dir=${start_dir}/ctrl

# Architecture
build_arch=voimaintel

# This file is used to store information about restarts
nemo_info_file="nemo.info"

# -----------------------------------------------------------------------------
# *** Read platform dependent configuration
# -----------------------------------------------------------------------------
source ./nemoconf.cfg

configure

# -----------------------------------------------------------------------------
# *** NEMO/LIM configuration
# -----------------------------------------------------------------------------

nem_version=3_6_STABLE
lim_version=3

nem_time_step_sec=720
lim_time_step_sec=3600

nem_restart_offset=0

nem_res_hor=$(echo ${nem_grid} | sed 's:ORCA\([0-9]\+\)L[0-9]\+:\1:')

has_config pisces \
&& nem_config_name=${nem_grid}_LIM${lim_version}_PISCES \
|| nem_config_name=${nem_grid}_LIM${lim_version}

nem_exe_file=${nemo_src_dir}/nemo_v${nem_version}/NEMOGCM/CONFIG/${nem_config_name}/BLD/bin/nemo.exe

nem_numproc=150

# -----------------------------------------------------------------------------
# *** XIOS configuration
# -----------------------------------------------------------------------------

xio_exe_file=${nemo_src_dir}/xios-1.0/bin/xios_server.exe

xio_numproc=20

# -----------------------------------------------------------------------------
# *** Define which NEMO forcing set and weight files to use
# -----------------------------------------------------------------------------
# NEMO forcing set
case ${nem_forcing_set} in
    DFS*) nem_forcing_dir=${ini_data_dir}/nemo/climate/${nem_forcing_set}
            nem_forcing_weight_dir=${ini_data_dir}/nemo/${nem_grid}/climate/${nem_forcing_set}/weights

            # Define DFS-NEMO weight files
            nem_forcing_weight_u10=weight_bicub_320x161-ORCA${nem_res_hor}.nc
            nem_forcing_weight_v10=weight_bicub_320x161-ORCA${nem_res_hor}.nc
            nem_forcing_weight_radsw=weight_bilin_192x94-ORCA${nem_res_hor}.nc
            nem_forcing_weight_radlw=weight_bilin_192x94-ORCA${nem_res_hor}.nc
            nem_forcing_weight_t2=weight_bilin_320x161-ORCA${nem_res_hor}.nc
            nem_forcing_weight_q2=weight_bilin_320x161-ORCA${nem_res_hor}.nc
            nem_forcing_weight_precip=weight_bilin_192x94-ORCA${nem_res_hor}.nc
            nem_forcing_weight_snow=weight_bilin_192x94-ORCA${nem_res_hor}.nc
            ;;
	ERAI*) nem_forcing_dir=/lustre/tmp/gierisch/forcing/downloadselbst
            ;;
         *) error "Unsupported NEMO forcing set: ${nem_forcing_set}"
            ;;
esac

# =============================================================================
# *** END of User configuration
# =============================================================================

# =============================================================================
# *** This is where the code begins ...
# =============================================================================

# -----------------------------------------------------------------------------
# *** Make sure to clean up on exit
# -----------------------------------------------------------------------------

trap 'cleanup' EXIT SIGHUP SIGINT SIGTERM

# -----------------------------------------------------------------------------
# *** Create the run dir if necessary and go there
#     Everything is done from here.
# -----------------------------------------------------------------------------
if [ ! -d ${run_dir} ]
then
    mkdir -p ${run_dir}
fi
cd ${run_dir}

# -----------------------------------------------------------------------------
# *** Determine the time span of this run and whether it's a restart leg
# -----------------------------------------------------------------------------

# Regularise the format of the start and end date of the simulation
run_start_date=$(date -uR -d "${run_start_date}")
run_end_date=$(date -uR -d "${run_end_date}")

# Loop over the number of legs
for (( ; run_num_legs>0 ; run_num_legs-- ))
do

    # Check for restart information file and set the current leg start date
    #   Ignore restart information file if force_run_from_scratch is true
    if ${force_run_from_scratch} || ! [ -r ${nemo_info_file} ]
    then
        leg_is_restart=false
        leg_start_date=${run_start_date}
        leg_number=1
    else
        leg_is_restart=true
        . ./${nemo_info_file}
        leg_start_date=${leg_end_date}
        leg_number=$((leg_number+1))
    fi

    # Compute the end date of the current leg
    if [ -n "${rst_freq}" ]
    then
        leg_end_date=$(date -uR -d "${leg_start_date} + ${rst_freq}")
    else
        leg_end_date=${run_end_date}
    fi

    if [ $(date -d "${leg_end_date}" +%s) -gt $(date -d "${run_end_date}" +%s) ]
    then
        leg_end_date=${run_end_date}
    fi

    # Some time variables needed later
    leg_length_sec=$(( $(date -d "${leg_end_date}" +%s) - $(date -d "${leg_start_date}" +%s) ))
    leg_start_sec=$(( $(date -d "${leg_start_date}" +%s) - $(date -d "${run_start_date}" +%s) ))
    leg_end_sec=$(( $(date -d "${leg_end_date}" +%s) - $(date -d "${run_start_date}" +%s) ))
    leg_start_date_yyyymmdd=$(date -u -d "${leg_start_date}" +%Y%m%d)
    leg_start_date_yyyy=$(date -u -d "${leg_start_date}" +%Y)
    leg_end_date_yyyy=$(date -u -d "${leg_end_date}" +%Y)

    # Correct for leap days because NEMO standalone uses no-leap calendar
    #leg_length_sec=$(( leg_length_sec - $(leap_days "${leg_start_date}" "${leg_end_date}")*24*3600 ))
    #leg_start_sec=$(( leg_start_sec - $(leap_days "${run_start_date}" "${leg_start_date}")*24*3600 ))
    #leg_end_sec=$(( leg_end_sec - $(leap_days "${run_start_date}" "${leg_end_date}")*24*3600 ))

    # Check whether there's actually time left to simulate - exit otherwise
    if [ ${leg_length_sec} -le 0 ]
    then
        info "Leg start date equal to or after end of simulation."
        info "Nothing left to do. Exiting."
        exit 0
    fi

    # -------------------------------------------------------------------------
    # *** Prepare the run directory for a run from scratch
    # -------------------------------------------------------------------------
    if ! $leg_is_restart
    then
        # ---------------------------------------------------------------------
        # *** Check if run dir is empty. If not, and if we are allowed to do so
        #     by ${force_run_from_scratch}, remove everything
        # ---------------------------------------------------------------------
        if $(ls * >& /dev/null)
        then
            if ${force_run_from_scratch}
            then
                rm -fr ${run_dir}/*
            else
                error "Run directory not empty and \$force_run_from_scratch not set."
            fi
        fi

        # ---------------------------------------------------------------------
        # *** Copy executables of model components
        # *** Additionally, create symlinks to the original place for reference
        # ---------------------------------------------------------------------
        cp    ${nem_exe_file} .
        ln -s ${nem_exe_file} $(basename ${nem_exe_file}).lnk

        cp    ${xio_exe_file} .
        ln -s ${xio_exe_file} $(basename ${xio_exe_file}).lnk

        # ---------------------------------------------------------------------
        # *** Files needed for NEMO (linked)
        # ---------------------------------------------------------------------

        # Various stuff
        ln -s ${ini_data_dir}/ORCA025_bathy_etopo1_gebco1_smoothed_coast_corrected_mar10.nc bathy_meter.nc
        ln -s ${ini_data_dir}/orca025_coordinates_280809.nc coordinates.nc
        if [ -f ${ini_data_dir}/ahmcoef ]
        then
            ln -s ${ini_data_dir}/ahmcoef
        fi

        # IOM files
        . ${ctrl_file_dir}/iodef.xml.sh > iodef.xml
        ln -s ${ctrl_file_dir}/domain_def.xml
        ln -s ${ctrl_file_dir}/field_def.xml

        # Initialisation data for temperature and salinity and ice
        ln -s ${ini_data_dir}/Levitus_p2.1_1m_Tpot_orca025.l75.nc data_1m_potential_temperature_nomask.nc
        ln -s ${ini_data_dir}/Levitus_p2.1_1m_S_correc_orca025.l75.nc data_1m_salinity_nomask.nc
        ln -s ${ini_data_dir}/Ice_initialization.nc

        # Forcing weight files
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_u10}
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_v10}
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_t2}
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_q2}
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_radsw}
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_radlw}
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_precip}
        #ln -fs ${nem_forcing_weight_dir}/${nem_forcing_weight_snow}

        # ---------------------------------------------------------------------
        # *** Files needed for TOP/PISCES (linked)
        # ---------------------------------------------------------------------

        if $(has_config pisces)
        then
            ln -fs ${ini_data_dir}/pisces/par.orca.nc
            ln -fs ${ini_data_dir}/pisces/dust.orca.nc
            ln -fs ${ini_data_dir}/pisces/solubility.orca.nc
            ln -fs ${ini_data_dir}/pisces/river.orca.nc
            ln -fs ${ini_data_dir}/pisces/bathy.orca.nc
            ln -fs ${ini_data_dir}/pisces/ndeposition.orca.nc
            ln -fs ${ini_data_dir}/pisces/data_DIC_nomask.nc
            ln -fs ${ini_data_dir}/pisces/data_Alkalini_nomask.nc
            ln -fs ${ini_data_dir}/pisces/data_O2_nomask.nc
            ln -fs ${ini_data_dir}/pisces/data_PO4_nomask.nc
            ln -fs ${ini_data_dir}/pisces/data_Si_nomask.nc
            ln -fs ${ini_data_dir}/pisces/data_DOC_nomask.nc
            ln -fs ${ini_data_dir}/pisces/data_Fer_nomask.nc
            ln -fs ${ini_data_dir}/pisces/data_NO3_nomask.nc
        fi

    else # i.e. $leg_is_restart == true

        # ---------------------------------------------------------------------
        # *** Remove all leftover output files from previous legs
        # ---------------------------------------------------------------------

        # NEMO output files
        rm -f ${exp_name}_??_????????_????????_{grid_U,grid_V,grid_W,grid_T,icemod,SBC}.nc

    fi # ! $leg_is_restart

    # -------------------------------------------------------------------------
    # *** Create some control files
    # -------------------------------------------------------------------------

    # NEMO and LIM namelists
    . ${ctrl_file_dir}/namelist_ref.sh                     > namelist_ref
    . ${ctrl_file_dir}/namelist_cfg.sh                     > namelist_cfg
    . ${ctrl_file_dir}/namelist_ice_ref.sh                 > namelist_ice_ref
    . ${ctrl_file_dir}/namelist_ice_cfg.sh                 > namelist_ice_cfg

    # NEMO/TOP+PISCES namelists
    has_config pisces && . ${ctrl_file_dir}/namelist.nemo.top.ref.sh    > namelist_top_ref
    has_config pisces && . ${ctrl_file_dir}/namelist.nemo.top.cfg.sh    > namelist_top_cfg
    has_config pisces && . ${ctrl_file_dir}/namelist.nemo.pisces.ref.sh > namelist_pisces_ref
    has_config pisces && . ${ctrl_file_dir}/namelist.nemo.pisces.cfg.sh > namelist_pisces_cfg

    # -------------------------------------------------------------------------
    # *** Link the appropriate NEMO restart files of the previous leg
    # -------------------------------------------------------------------------
    if $leg_is_restart
    then
        ns=$(printf %08d $(( leg_start_sec / nem_time_step_sec - nem_restart_offset )))
        for (( n=0 ; n<nem_numproc ; n++ ))
        do
            np=$(printf %04d ${n})
            ln -fs ${exp_name}_${ns}_restart_oce_${np}.nc restart_oce_${np}.nc
            ln -fs ${exp_name}_${ns}_restart_ice_${np}.nc restart_ice_${np}.nc
            has_config pisces && \
            ln -fs ${exp_name}_${ns}_restart_trc_${np}.nc restart_trc_${np}.nc
        done
    fi

    # -------------------------------------------------------------------------
    # *** Link the appropriate NEMO forcing files for the current year
    # -------------------------------------------------------------------------
    ln -fs ${nem_forcing_dir}/u10m_${nem_forcing_set}_${leg_start_date_yyyy}.nc u10m_y${leg_start_date_yyyy}.nc
    ln -fs ${nem_forcing_dir}/v10m_${nem_forcing_set}_${leg_start_date_yyyy}.nc v10m_y${leg_start_date_yyyy}.nc
    ln -fs ${nem_forcing_dir}/t2m_${nem_forcing_set}_${leg_start_date_yyyy}.nc t2m_y${leg_start_date_yyyy}.nc
    ln -fs ${nem_forcing_dir}/q2m_${nem_forcing_set}_${leg_start_date_yyyy}.nc q2m_y${leg_start_date_yyyy}.nc
    ln -fs ${nem_forcing_dir}/precip_${nem_forcing_set}_${leg_start_date_yyyy}.nc precip_y${leg_start_date_yyyy}.nc
    ln -fs ${nem_forcing_dir}/snow_${nem_forcing_set}_${leg_start_date_yyyy}.nc snow_y${leg_start_date_yyyy}.nc
    ln -fs ${nem_forcing_dir}/lwrad_${nem_forcing_set}_${leg_start_date_yyyy}.nc lwrad_y${leg_start_date_yyyy}.nc
    ln -fs ${nem_forcing_dir}/swrd_${nem_forcing_set}_${leg_start_date_yyyy}.nc swrd_y${leg_start_date_yyyy}.nc

    # Runoff climatology
    ln -fs ${ini_data_dir}/runoff.nc runoff_core_monthly.nc

    # Sea surface restoring
    ln -fs ${ini_data_dir}/Levitus_p2_1m_SSS_v2_orca05.l75.nc sss_data.nc

    # Chlorophyll
    ln -fs ${ini_data_dir}/chlorophyll.nc

    # Tides
    ln -fs ${ini_data_dir}/K1rowdrg.nc
    ln -fs ${ini_data_dir}/M2rowdrg.nc

    # ITF mask
    ln -fs ${ini_data_dir}/mask_itf_ORCA025.nc mask_itf.nc

    # -------------------------------------------------------------------------
    # *** Start the run
    # -------------------------------------------------------------------------

    # Use the launch function from the platform configuration file
    t1=$(date +%s)
    launch \
        ${nem_numproc} ${nem_exe_file} -- \
        ${xio_numproc} ${xio_exe_file}
    t2=$(date +%s)

    tr=$(date -d "0 -$t1 sec + $t2 sec" +%T)

    # -------------------------------------------------------------------------
    # *** Check for signs of success
    #     Note the tests provide no guarantee that things went fine! They are
    #     just based on the IFS and NEMO log files. More tests (e.g. checking
    #     restart files) could be implemented.
    # -------------------------------------------------------------------------
    # Check for NEMO success
    if [ -f ocean.output ]
    then
        if [ "$(awk '/New day/{d=$10}END{print d}' ocean.output)" == "$(date -d "${leg_end_date} - 1 day" +%Y/%m/%d)" ]
        then
            info "Leg successfully completed according to NEMO log file 'ocean.output'."
        else
            error "Leg not completed according to NEMO log file 'ocean.output'."
        fi

    else
        error "NEMO log file 'ocean.output' not found after run."
    fi

    # -------------------------------------------------------------------------
    # *** Move NEMO output files to archive directory
    # -------------------------------------------------------------------------
    outdir="output/nemo/$(printf %03d $((leg_number)))"
    mkdir -p ${outdir}

    for v in grid_U grid_V grid_W grid_T icemod SBC
    do
        for f in ${exp_name}_??_????????_????????_${v}.nc
        do
            test -f $f && mv $f $outdir/
        done
    done

    # -------------------------------------------------------------------------
    # *** Move NEMO restart files to archive directory
    # -------------------------------------------------------------------------
    if $leg_is_restart
    then
        outdir="restart/nemo/$(printf %03d $((leg_number)))"
        mkdir -p ${outdir}

        ns=$(printf %08d $(( leg_start_sec / nem_time_step_sec - nem_restart_offset )))
        for f in oce ice
        do
            frst=${exp_name}_${ns}_restart_${f}.nc
            if [ -f $frst ]
            then
                mv ${exp_name}_${ns}_restart_${f}.nc ${outdir}
            else
                mv ${exp_name}_${ns}_restart_${f}_????.nc ${outdir}
            fi
        done
    fi

    # -------------------------------------------------------------------------
    # *** Move log files to archive directory
    # -------------------------------------------------------------------------
    outdir="log/$(printf %03d $((leg_number)))"
    mkdir -p ${outdir}

    for f in \
        ocean.output time.step solver.stat
    do
        test -f ${f} && mv ${f} ${outdir}
    done

    # -------------------------------------------------------------------------
    # *** Write the restart control file
    # -------------------------------------------------------------------------

    echo "#"                                             | tee -a ${nemo_info_file}
    echo "# Finished leg at `date '+%F %T'` after ${tr} (hh:mm:ss)" \
                                                         | tee -a ${nemo_info_file}
    echo "leg_number=${leg_number}"                      | tee -a ${nemo_info_file}
    echo "leg_start_date=\"${leg_start_date}\""          | tee -a ${nemo_info_file}
    echo "leg_end_date=\"${leg_end_date}\""              | tee -a ${nemo_info_file}

    # Need to reset force_run_from_scratch in order to avoid destroying the next leg
    force_run_from_scratch=false

done # loop over legs

# -----------------------------------------------------------------------------
# *** Platform dependent finalising of the run
# -----------------------------------------------------------------------------
finalise

exit 0
