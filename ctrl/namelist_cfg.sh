# namelist_cfg.sh writes the NEMO namelist for
# ORCA025L75 in coupled mode to standard output.

cat << EOF
!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
!! NEMO/OPA  Configuration namelist : used to overwrite defaults values defined in SHARED/namelist_ref
!!>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
!
!-----------------------------------------------------------------------
&namrun        !   parameters of the run
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namcfg        !   parameters of the configuration
!-----------------------------------------------------------------------
   cp_cfg      =  "orca"               !  name of the configuration
   jp_cfg      =       025             !  resolution of the configuration
   jpidta      =      1442             !  1st lateral dimension ( >= jpi )
   jpjdta      =      1021             !  2nd    "         "    ( >= jpj )
   jpkdta      =      75               !  number of levels      ( >= jpk )
   jpiglo      =      1442             !  1st dimension of global domain --> i =jpidta
   jpjglo      =      1021             !  2nd    -                  -    --> j  =jpjdta
   jpizoom     =       1               !  left bottom (i,j) indices of the zoom
   jpjzoom     =       1               !  in data domain indices
   jperio      =       4               !  lateral cond. type (between 0 and 6)
/
!-----------------------------------------------------------------------
&namzgr        !   vertical coordinate
!-----------------------------------------------------------------------
   ln_zco      = .false.   !  z-coordinate - full    steps   (T/F)      ("key_zco" may also be defined)
   ln_zps      = .true.    !  z-coordinate - partial steps   (T/F)
   ln_sco      = .false.   !  s- or hybrid z-s-coordinate    (T/F)
   ln_isfcav   = .false.   !  ice shelf cavity
/
!-----------------------------------------------------------------------
&namdom        !   space and time domain (bathymetry, mesh, timestep)
!-----------------------------------------------------------------------
   nn_bathy    =    1      !  compute (=0) or read (=1) the bathymetry file
   rn_bathy    =    0.     !  value of the bathymetry. if (=0) bottom flat at jpkm1
   nn_closea   =    0      !  remove (=0) or keep (=1) closed seas and lakes (ORCA)
   nn_msh      =    0      !  create (=1) a mesh file or not (=0)
                           !  if not 0 can be in [1 - 6 ] for drakkar usually 6
   rn_hmin     =   -3.     !  min depth of the ocean (>0) or min number of ocean level (<0)
   rn_e3zps_min=   25.     !  partial step thickness is set larger than the minimum of
   rn_e3zps_rat=    0.2    !  rn_e3zps_min and rn_e3zps_rat*e3t, with 0<rn_e3zps_rat<1
                           !
   rn_rdt      = ${nem_time_step_sec} !  time step for the dynamics (and tracer if nn_acc=0)
   rn_atfp     =    0.1    !  asselin time filter parameter
   nn_acc      =    0      !  acceleration of convergence : =1      used, rdt < rdttra(k)
                           !                                =0, not used, rdt = rdttra
   rn_rdtmin   = 1080.     !  minimum time step on tracers (used if nn_acc=1)
   rn_rdtmax   = 1080.     !  maximum time step on tracers (used if nn_acc=1)
   rn_rdth     =  800.     !  depth variation of tracer time step  (used if nn_acc=1)
   ln_crs      = .false.   !  Logical switch for coarsening module (see namcrs if true)
   jphgr_msh   =       0               !  type of horizontal mesh
                                       !  = 0 curvilinear coordinate on the sphere read in coordinate.nc
                                       !  = 1 geographical mesh on the sphere with regular grid-spacing
                                       !  = 2 f-plane with regular grid-spacing
                                       !  = 3 beta-plane with regular grid-spacing
                                       !  = 4 Mercator grid with T/U point at the equator
   ppglam0     =        999999.        !  longitude of first raw and column T-point (jphgr_msh = 1)
   ppgphi0     =        999999.        ! latitude  of first raw and column T-point (jphgr_msh = 1)
   ppe1_deg    =        999999.        !  zonal      grid-spacing (degrees)
   ppe2_deg    =        999999.        !  meridional grid-spacing (degrees)
   ppe1_m      =        999999.        !  zonal      grid-spacing (degrees)
   ppe2_m      =        999999.        !  meridional grid-spacing (degrees)
   ppsur       =    -3958.951371276829 !  ORCA r4, r2 and r05 coefficients
   ppa0        =     103.9530096000000 ! (default coefficients)
   ppa1        =     2.415951269000000 !
   ppkth       =     15.35101370000000 !
   ppacr       =        7.0            !
   ppdzmin     =       999999.         !  Minimum vertical spacing
   pphmax      =       999999.         !  Maximum depth
   ldbletanh   =    .true.             !  Use/do not use double tanf function for vertical coordinates
   ppa2        =     100.7609285000000 !  Double tanh function parameters
   ppkth2      =       48.029893720000 !
   ppacr2      =       13.000000000000 !
/
!-----------------------------------------------------------------------
&namsplit      !   time splitting parameters                            ("key_dynspg_ts")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namcrs        !   Grid coarsening for dynamics output and/or
               !   passive tracer coarsened online simulations
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namtsd    !   data : Temperature  & Salinity
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc        !   Surface Boundary Condition (surface module)
!-----------------------------------------------------------------------
   ln_blk_core = .true.    !  CORE bulk formulation                     (T => fill namsbc_core)
   ln_blk_mfs  = .false.   !  MFS bulk formulation                      (T => fill namsbc_mfs )
   ln_apr_dyn  = .false.   !  Patm gradient added in ocean & ice Eqs.   (T => fill namsbc_apr )
   nn_ice      = 2         !  =0 no ice boundary condition   ,
                           !  =1 use observed ice-cover      ,
                           !  =2 ice-model used                         ("key_lim3" or "key_lim2)
   ln_ssr      = .true.    !  Sea Surface Restoring on T and/or S       (T => fill namsbc_ssr)
   nn_fwb      = 0         !  FreshWater Budget: =0 unchecked
                           !     =1 global mean of e-p-r set to zero at each time step
                           !     =2 annual global mean of e-p-r set to zero
/
!-----------------------------------------------------------------------
&namsbc_core   !   namsbc_core  CORE bulk formulae
!-----------------------------------------------------------------------
!          !  file name            ! frequency (hours) ! variable ! time interp. !  clim  ! 'yearly'/ ! weights                      ! rotation ! land/sea mask !
!          !                       !  (if <0  months)  !   name   !   (logical)  !  (T/F) ! 'monthly' ! filename                     ! pairing  ! filename      !
   sn_wndi     = 'u10m'             ,       3           , 'u10m'     ,    .true.      , .false.  , 'yearly'  , ''  , ''
   sn_wndj     = 'v10m'             ,       3           , 'v10m'     ,    .true.      , .false.  , 'yearly'  , ''  , ''
   sn_qsr      = 'swrd'             ,       24          , 'swrd'     ,    .false.     , .false.  , 'yearly'  , ''  , ''
   sn_qlw      = 'lwrad'            ,       24          , 'lwrad'    ,    .true.      , .false.  , 'yearly'  , ''  , ''
   sn_tair     = 't2m'              ,       3           , 't2m'      ,    .true.      , .false.  , 'yearly'  , ''  , ''
   sn_humi     = 'q2m'              ,       3           , 'q2m'      ,    .true.      , .false.  , 'yearly'  , ''  , ''
   sn_prec     = 'precip'           ,       24          , 'precip'   ,    .true.      , .false.  , 'yearly'  , ''  , ''
   sn_snow     = 'snow'             ,       24          , 'snow'     ,    .true.      , .false.  , 'yearly'  , ''  , ''
   sn_tdif =     'taudif'              ,    24        ,  'taudif' ,    .true.    , .false. ,  'yearly'  ,  ''                           , ''   , ""
   cn_dir      = './'      !  root directory for the location of the bulk files
   ln_taudif   = .false.   !  HF tau contribution: use "mean of stress module - module of the mean stress" data
   rn_zqt      = 2.        !  Air temperature and humidity reference height (m)
   rn_zu       = 10.       !  Wind vector reference height (m)
   rn_pfac     = 1.        !  multiplicative factor for precipitation (total & snow)
   rn_efac     = 1.        !  multiplicative factor for evaporation (0. or 1.)
   rn_vfac     = 1.        !  multiplicative factor for ocean/ice velocity 
                           !  in the calculation of the wind stress (0.=absolute winds or 1.=relative winds)
/
!-----------------------------------------------------------------------
&namtra_qsr    !   penetrative solar radiation
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc_rnf    !   runoffs namelist surface boundary condition
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsbc_ssr    !   surface boundary condition : sea surface restoring
!-----------------------------------------------------------------------
!              !  file name  ! frequency (hours) ! variable  ! time interp. !  clim  ! 'yearly'/ ! weights  ! rotation ! land/sea mask !
!              !             !  (if <0  months)  !   name    !   (logical)  !  (T/F) ! 'monthly' ! filename ! pairing  ! filename      !
   sn_sst      = 'sst_data'  ,        -1         , 'votemper',    .false.   , .true. , 'yearly'  , ''       , ''
   sn_sss      = 'sss_data'  ,        -1         , 'vosaline',    .false.   , .true. , 'yearly'  , ''       , ''
   cn_dir      = './'      !  root directory for the location of the runoff files
   nn_sstr     =     0     !  add a retroaction term in the surface heat       flux (=1) or not (=0)
   nn_sssr     =     2     !  add a damping     term in the surface freshwater flux (=2)
                           !  or to SSS only (=1) or no damping term (=0)
   rn_dqdt     =   -40.    !  magnitude of the retroaction on temperature   [W/m2/K]
   rn_deds     =  -166.667 !  magnitude of the damping on salinity   [mm/day]
   ln_sssr_bnd =   .true.  !  flag to bound erp term (associated with nn_sssr=2)
   rn_sssr_bnd =   4.e0    !  ABS(Max/Min) value of the damping erp term [mm/day]
/
!-----------------------------------------------------------------------
&namsbc_alb    !   albedo parameters
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namberg       !   iceberg parameters
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namlbc        !   lateral momentum boundary condition
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namcla        !   cross land advection
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nambfr        !   bottom friction
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nambbc        !   bottom temperature boundary condition
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nambbl        !   bottom boundary layer scheme
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nameos        !   ocean physical parameters
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namtra_adv    !   advection scheme for tracer
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namtra_adv_mle !  mixed layer eddy parametrisation (Fox-Kemper param)
!-----------------------------------------------------------------------
/
!----------------------------------------------------------------------------------
&namtra_ldf    !   lateral diffusion scheme for tracers
!----------------------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namtra_dmp    !   tracer: T & S newtonian damping
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdyn_adv    !   formulation of the momentum advection
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdyn_vor    !   option of physics/algorithm (not control by CPP keys)
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdyn_hpg    !   Hydrostatic pressure gradient option
!-----------------------------------------------------------------------
   ln_hpg_zco  = .false.   !  z-coordinate - full steps
   ln_hpg_zps  = .false.   !  z-coordinate - partial steps (interpolation)
   ln_hpg_sco  = .false.   !  s-coordinate (standard jacobian formulation)
   ln_hpg_djc  = .false.   !  s-coordinate (Density Jacobian with Cubic polynomial)
   ln_hpg_prj  = .true.    !  s-coordinate (Pressure Jacobian scheme)
   ln_dynhpg_imp = .false. !  time stepping: semi-implicit time scheme  (T)
                                 !           centered      time scheme  (F)
/
!-----------------------------------------------------------------------
&namdyn_ldf    !   lateral diffusion on momentum
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf        !   vertical physics
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_tke    !   turbulent eddy kinetic dependent vertical diffusion  ("key_zdftke")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_ddm    !   double diffusive mixing parameterization             ("key_zdfddm")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namzdf_tmx    !   tidal mixing parameterization                        ("key_zdftmx")
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namsol        !   elliptic solver / island / free surface
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&nammpp        !   Massively Parallel Processing                        ("key_mpp_mpi)
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namctl        !   Control prints & Benchmark
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namptr       !   Poleward Transport Diagnostic
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namhsb       !  Heat and salt budgets
!-----------------------------------------------------------------------
/
!-----------------------------------------------------------------------
&namdyn_nept  !   Neptune effect (simplified: lateral and vertical diffusions removed)
!-----------------------------------------------------------------------
/
EOF
