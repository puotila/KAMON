# Find out if we run attached or detached (default is detached)
has_config xios:attached && using_server=false || using_server=true
has_config xios:detached && using_server=true

# Find out if we are using OASIS and set using_oasis accordingly
has_config oasis && using_oasis=true || using_oasis=false

# Write PISCES fields only if PISCES is active
has_config pisces && pisces_output='.TRUE.' || pisces_output='.FALSE.'

cat << EOF
<?xml version="1.0"?>
<simulation> 

 <context id="nemo" time_origin="1950-01-01 00:00:00" >
    <!-- 
============================================================================================================
=                                  definition of all existing variables                                    =
=                                            DO NOT CHANGE                                                 =
============================================================================================================
    -->
    <field_definition src="./field_def.xml"/>
    <!-- 
============================================================================================================
=                                           output files definition                                        =
=                                            Define your own files                                         =
=                                         put the variables you want...                                    =
============================================================================================================
    -->
    
    <file_definition type="one_file" name="@expname@_@freq@_@startdate@_@enddate@" sync_freq="10d" min_digits="4">
    
      <file_group id="1ts" output_freq="1ts"  output_level="10" enabled=".TRUE."/> <!-- 1 time step files -->

      <file_group id="1h" output_freq="1h"  output_level="10" enabled=".TRUE."/> <!-- 1h files -->

      <file_group id="2h" output_freq="2h"  output_level="10" enabled=".TRUE."/> <!-- 2h files -->

      <file_group id="3h" output_freq="3h"  output_level="10" enabled=".TRUE."/> <!-- 3h files -->     

      <file_group id="4h" output_freq="4h"  output_level="10" enabled=".TRUE."/> <!-- 4h files -->

      <file_group id="6h" output_freq="6h"  output_level="10" enabled=".TRUE."/> <!-- 6h files -->     

      <file_group id="1d" output_freq="1d"  output_level="10" enabled=".TRUE."> <!-- 1d files -->

	<file id="file8" name_suffix="_grid_T" description="ocean T grid variables" >
	  <field field_ref="sst"          name="tos"      long_name="sea_surface_temperature"                       />
	  <field field_ref="sss"          name="sos"      long_name="sea_surface_salinity"                          />
	  <field field_ref="ssh"          name="zos"      long_name="sea_surface_height_above_geoid"                />
	</file>

	<file id="file9" name_suffix="_icemod" description="ice variables" enabled=".true." >
          <field field_ref="icevolu"          name="sivolu" />
          <field field_ref="iceconc"          name="siconc"  />
          <field field_ref="uice_ipa"         name="sivelu" />
          <field field_ref="vice_ipa"         name="sivelv" />
	</file>

	<file id="file10" name_suffix="_grid_U" description="ocean U grid variables" >
	  <field field_ref="ssu"          name="uos"     long_name="sea_surface_x_velocity"    />
	</file>

	<file id="file11" name_suffix="_grid_V" description="ocean V grid variables" >
	  <field field_ref="ssv"          name="vos"     long_name="sea_surface_y_velocity"    />
	</file>

      </file_group>

      <file_group id="3d" output_freq="3d"  output_level="10" enabled=".TRUE."/> <!-- 3d files -->    

      <file_group id="5d" output_freq="5d"  output_level="10" enabled=".TRUE."/>  <!-- 5d files -->   

      <file_group id="1m" output_freq="1mo" output_level="10" enabled=".TRUE."> <!-- real monthly files -->

	<file id="file1" name_suffix="_grid_T" description="ocean T grid variables" >
	  <field field_ref="e3t"          />
	  <field field_ref="toce"         name="thetao"   long_name="sea_water_potential_temperature"                    operation="instant" freq_op="5d" > @toce_e3t / @e3t </field>
	  <field field_ref="soce"         name="so"       long_name="sea_water_salinity"                                 operation="instant" freq_op="5d" > @soce_e3t / @e3t </field>
	  <field field_ref="sst"          name="tos"      long_name="sea_surface_temperature"                       />
	  <field field_ref="sss"          name="sos"      long_name="sea_surface_salinity"                          />
	  <field field_ref="ssh"          name="zos"      long_name="sea_surface_height_above_geoid"                />
	  <field field_ref="sst"          name="tosstd"   long_name="sea_surface_temperature_standard_deviation"         operation="instant" freq_op="5d" > sqrt( @sst2 - @sst * @sst ) </field>
	  <field field_ref="ssh"          name="zosstd"   long_name="sea_surface_height_above_geoid_standard_deviation"  operation="instant" freq_op="5d" > sqrt( @ssh2 - @ssh * @ssh ) </field>
	  <field field_ref="sst"          name="sstdcy"   long_name="amplitude of sst diurnal cycle" operation="average" freq_op="1d" > @sstmax - @sstmin </field>
	  <field field_ref="mldkz5"       />
	  <field field_ref="mldr10_1"     />
	  <field field_ref="mldr10_1"     name="mldr10_1dcy"  long_name="amplitude of mldr10_1 diurnal cycle" operation="average" freq_op="1d" > @mldr10_1max - @mldr10_1min </field>
	  <field field_ref="sbt"                          />
	  <field field_ref="heatc"        name="heatc"    long_name="Heat content vertically integrated"            />
	  <field field_ref="saltc"        name="saltc"    long_name="Salt content vertically integrated"            />
	</file>

	<file id="file2" name_suffix="_SBC" description="surface fluxes variables" > <!-- time step automaticaly defined based on nn_fsbc -->
	  <field field_ref="empmr"        name="wfo"      long_name="water_flux_into_sea_water"                     />
	  <field field_ref="qsr_oce"      name="qsr_oce"  long_name="downward shortwave flux at ocean surface"           />
	  <field field_ref="qns_oce"      name="qns_oce"  long_name="downward non solar flux at ocean surface"           />
	  <field field_ref="qt_oce"       name="qt_oce"   long_name="downward total flux at ocean surface"           />
	  <field field_ref="qsr_ice"      name="qsr_ice"  long_name="downward shortwave flux at ice surface"           />
	  <field field_ref="qns_ice"      name="qns_ice"  long_name="downward non solar flux at ice surface"           />
	  <field field_ref="qtr_ice"      name="qtr_ice"  long_name="shortwave flux transmitted thru the ice"           />
	  <field field_ref="qt_ice"       name="qt_ice"   long_name="downward total flux at ice surface"           />
	  <field field_ref="saltflx"      name="sfx"     />
      <field field_ref="precip"       name="precip"  />
	  <!-- ice and snow -->
	  <field field_ref="snowpre" />
	  <field field_ref="utau_ice"     name="utau_ice" />
	  <field field_ref="vtau_ice"     name="vtau_ice" />
	</file>

	<file id="file3" name_suffix="_grid_U" description="ocean U grid variables" >
	  <field field_ref="ssu"          name="uos"     long_name="sea_surface_x_velocity"    />
	  <field field_ref="uoce"         name="uo"      long_name="sea_water_x_velocity" operation="instant" freq_op="5d" > @uoce_e3u / @e3u </field>
	  <field field_ref="utau"         name="tauuo"   long_name="surface_downward_x_stress" />
          <!-- available with key_diaar5 -->
	  <field field_ref="u_masstr"     name="vozomatr" />
	  <field field_ref="u_heattr"     name="sozohetr" />
      <field field_ref="u_salttr"     name="sozosatr" />
	</file>
	
	<file id="file4" name_suffix="_grid_V" description="ocean V grid variables" >
	  <field field_ref="ssv"          name="vos"     long_name="sea_surface_y_velocity"    />
	  <field field_ref="voce"         name="vo"      long_name="sea_water_y_velocity" operation="instant" freq_op="5d" > @voce_e3v / @e3v </field>
	  <field field_ref="vtau"         name="tauvo"   long_name="surface_downward_y_stress" />
          <!-- available with key_diaar5 -->
	  <field field_ref="v_masstr"     name="vomematr" />
	  <field field_ref="v_heattr"     name="somehetr" />
      <field field_ref="v_salttr"     name="somesatr" />
	</file>
	
	<file id="file5" name_suffix="_grid_W" description="ocean W grid variables" >
	  <field field_ref="w_masstr"     name="vovematr" />
	</file>

	<file id="file6" name_suffix="_icemod" description="ice variables" enabled=".true." >
	  <field field_ref="snowthic_cea"     name="snthic"     long_name="surface_snow_thickness"   />
	  <field field_ref="icethic_cea"      name="sithic"     long_name="sea_ice_thickness"        />
          <field field_ref="icevolu"          name="sivolu" />
          <field field_ref="snowvol"          name="snvolu" />
          <field field_ref="iceconc"          name="siconc"  />

          <field field_ref="vfxbog"          name="vfxbog" />
          <field field_ref="vfxdyn"          name="vfxdyn" />
          <field field_ref="vfxopw"          name="vfxopw" />
          <field field_ref="vfxsni"          name="vfxsni" />
          <field field_ref="vfxsum"          name="vfxsum" />
          <field field_ref="vfxbom"          name="vfxbom" />
          <field field_ref="vfxres"          name="vfxres" />
          <field field_ref="vfxice"          name="vfxice" />
          <field field_ref="vfxsnw"          name="vfxsnw" />
          <field field_ref="vfxsub"          name="vfxsub" />
          <field field_ref="vfxspr"          name="vfxspr" />

          <field field_ref="sfx"             name="sfx"    />

	  <!-- diags -->
          <field field_ref="micesalt"        name="sisali" />
          <field field_ref="micet"           name="sitemp" />
          <field field_ref="icest"           name="sistem" />
          <field field_ref="icehc"           name="siheco" />
          <field field_ref="isnowhc"         name="snheco" />
          <field field_ref="miceage"         name="siages" />

          <field field_ref="uice_ipa"        name="sivelu" />
          <field field_ref="vice_ipa"        name="sivelv" />
          <field field_ref="idive"           name="sidive" />
          <field field_ref="ishear"          name="sishea" />
          <field field_ref="icestr"          name="sistre" />

          <field field_ref="ibrinv"          name="sibrin" />
          <field field_ref="icecolf"         name="sicolf" />

          <field field_ref="iceage_cat"      name="siagecat" />
          <field field_ref="iceconc_cat"     name="siconcat" />
          <field field_ref="icethic_cat"     name="sithicat" />
          <field field_ref="snowthic_cat"    name="snthicat" />
          <field field_ref="salinity_cat"    name="salincat" />

	</file>

        <file id="file7" name_suffix="_scalar" description="scalar variables" enabled=".true." >
          <field field_ref="voltot"       name="scvoltot"   />
          <field field_ref="sshtot"       name="scsshtot"   />
          <field field_ref="sshsteric"    name="scsshste"   />
          <field field_ref="sshthster"    name="scsshtst"   />
          <field field_ref="masstot"      name="scmastot"   />
          <field field_ref="temptot"      name="sctemtot"   />
          <field field_ref="saltot"       name="scsaltot"   />

          <field field_ref="bgtemper"     name="bgtemper"   />
          <field field_ref="bgsaline"     name="bgsaline"   />
          <field field_ref="bgheatco"     name="bgheatco"   />
          <field field_ref="bgsaltco"     name="bgsaltco"   />
          <field field_ref="bgvolssh"     name="bgvolssh"   /> 
          <field field_ref="bgvole3t"     name="bgvole3t"   />
          <field field_ref="bgfrcvol"     name="bgfrcvol"   />
          <field field_ref="bgfrctem"     name="bgfrctem"   />
          <field field_ref="bgfrcsal"     name="bgfrcsal"   />

          <field field_ref="ibgvoltot"    name="ibgvoltot"  />
          <field field_ref="sbgvoltot"    name="sbgvoltot"  />
          <field field_ref="ibgarea"      name="ibgarea"    />
          <field field_ref="ibgsaline"    name="ibgsaline"  />
          <field field_ref="ibgtemper"    name="ibgtemper"  />
          <field field_ref="ibgheatco"    name="ibgheatco"  />
          <field field_ref="sbgheatco"    name="sbgheatco"  />
          <field field_ref="ibgsaltco"    name="ibgsaltco"  />

          <field field_ref="ibgvfx"       name="ibgvfx"     />
          <field field_ref="ibgvfxbog"    name="ibgvfxbog"  />
          <field field_ref="ibgvfxopw"    name="ibgvfxopw"  />
          <field field_ref="ibgvfxsni"    name="ibgvfxsni"  />
          <field field_ref="ibgvfxdyn"    name="ibgvfxdyn"  />
          <field field_ref="ibgvfxbom"    name="ibgvfxbom"  />
          <field field_ref="ibgvfxsum"    name="ibgvfxsum"  />
          <field field_ref="ibgvfxres"    name="ibgvfxres"  />
          <field field_ref="ibgvfxspr"    name="ibgvfxspr"  />
          <field field_ref="ibgvfxsnw"    name="ibgvfxsnw"  />
          <field field_ref="ibgvfxsub"    name="ibgvfxsub"  />

          <field field_ref="ibgsfx"       name="ibgsfx"     />
          <field field_ref="ibgsfxbri"    name="ibgsfxbri"  />
          <field field_ref="ibgsfxdyn"    name="ibgsfxdyn"  />
          <field field_ref="ibgsfxres"    name="ibgsfxres"  />
          <field field_ref="ibgsfxbog"    name="ibgsfxbog"  />
          <field field_ref="ibgsfxopw"    name="ibgsfxopw"  />
          <field field_ref="ibgsfxsni"    name="ibgsfxsni"  />
          <field field_ref="ibgsfxbom"    name="ibgsfxbom"  />
          <field field_ref="ibgsfxsum"    name="ibgsfxsum"  />

          <field field_ref="ibghfxdhc"    name="ibghfxdhc"  />
          <field field_ref="ibghfxspr"    name="ibghfxspr"  />

          <field field_ref="ibghfxres"    name="ibghfxres"  />
          <field field_ref="ibghfxsub"    name="ibghfxsub"  />
          <field field_ref="ibghfxdyn"    name="ibghfxdyn"  />
          <field field_ref="ibghfxthd"    name="ibghfxthd"  />
          <field field_ref="ibghfxsum"    name="ibghfxsum"  />
          <field field_ref="ibghfxbom"    name="ibghfxbom"  />
          <field field_ref="ibghfxbog"    name="ibghfxbog"  />
          <field field_ref="ibghfxdif"    name="ibghfxdif"  />
          <field field_ref="ibghfxopw"    name="ibghfxopw"  />
          <field field_ref="ibghfxout"    name="ibghfxout"  />
          <field field_ref="ibghfxin"     name="ibghfxin"   />
          <field field_ref="ibghfxsnw"    name="ibghfxsnw"  />

          <field field_ref="ibgfrcvol"    name="ibgfrcvol"  />
          <field field_ref="ibgfrcsfx"    name="ibgfrcsfx"  />
          <field field_ref="ibgvolgrm"    name="ibgvolgrm"  />

        </file>

	<!--
	<file id="file8" name_suffix="_Tides" description="tidal harmonics" >
	  <field field_ref="M2x"          name="M2x"      long_name="M2 Elevation harmonic real part"                       />
	  <field field_ref="M2y"          name="M2y"      long_name="M2 Elevation harmonic imaginary part"                  />
	  <field field_ref="M2x_u"        name="M2x_u"    long_name="M2 current barotrope along i-axis harmonic real part "       />
	  <field field_ref="M2y_u"        name="M2y_u"    long_name="M2 current barotrope along i-axis harmonic imaginary part "  />
	  <field field_ref="M2x_v"        name="M2x_v"    long_name="M2 current barotrope along j-axis harmonic real part "       />
	  <field field_ref="M2y_v"        name="M2y_v"    long_name="M2 current barotrope along j-axis harmonic imaginary part "  />
	</file>
	-->

      </file_group>

      <file_group id="2m" output_freq="2mo" output_level="10" enabled=".TRUE."/> <!-- real 2m files -->
      <file_group id="3m" output_freq="3mo" output_level="10" enabled=".TRUE."/> <!-- real 3m files -->
      <file_group id="4m" output_freq="4mo" output_level="10" enabled=".TRUE."/> <!-- real 4m files -->
      <file_group id="6m" output_freq="6mo" output_level="10" enabled=".TRUE."/> <!-- real 6m files -->

      <file_group id="1y"  output_freq="1y" output_level="10" enabled=".TRUE."/> <!-- real yearly files -->
      <file_group id="2y"  output_freq="2y" output_level="10" enabled=".TRUE."/> <!-- real 2y files -->
      <file_group id="5y"  output_freq="5y" output_level="10" enabled=".TRUE."/> <!-- real 5y files -->
      <file_group id="10y" output_freq="10y" output_level="10" enabled=".TRUE."/> <!-- real 10y files -->

   </file_definition>
    
    <!-- 
============================================================================================================
= grid definition = = DO NOT CHANGE =
============================================================================================================
    -->
    
   <axis_definition>  
      <axis id="deptht"  long_name="Vertical T levels"  unit="m" positive="down" />
      <axis id="depthu"  long_name="Vertical U levels"  unit="m" positive="down" />
      <axis id="depthv"  long_name="Vertical V levels"  unit="m" positive="down" />
      <axis id="depthw"  long_name="Vertical W levels"  unit="m" positive="down" />
      <axis id="nfloat"  long_name="Float number"       unit="1"                 />
      <axis id="icbcla"  long_name="Iceberg class"      unit="1"                 />
      <axis id="ncatice" long_name="Ice category"       unit="1"                 />
      <axis id="iax_20C" long_name="20 degC isotherm"   unit="degC"              />
      <axis id="iax_28C" long_name="28 degC isotherm"   unit="degC"              />
   </axis_definition> 
    
   <domain_definition src="./domain_def.xml"/>
   
   <grid_definition>    
     <grid id="grid_T_2D" domain_ref="grid_T"/>
     <grid id="grid_T_3D" domain_ref="grid_T" axis_ref="deptht"/>
     <grid id="grid_U_2D" domain_ref="grid_U"/>
     <grid id="grid_U_3D" domain_ref="grid_U" axis_ref="depthu"/>
     <grid id="grid_V_2D" domain_ref="grid_V"/>
     <grid id="grid_V_3D" domain_ref="grid_V" axis_ref="depthv"/>
     <grid id="grid_W_2D" domain_ref="grid_W"/>
     <grid id="grid_W_3D" domain_ref="grid_W" axis_ref="depthw"/>
     <grid id="gznl_T_2D" domain_ref="gznl"/>
     <grid id="gznl_T_3D" domain_ref="gznl" axis_ref="deptht"/>
     <grid id="gznl_W_3D" domain_ref="gznl" axis_ref="depthw"/>
    </grid_definition>   
  </context>
  

  <context id="xios">

      <variable_definition>
	
     <!-- 
        We must have buffer_size > jpi*jpj*jpk*8 (with jpi and jpj the subdomain size)
-->
	  <variable id="buffer_size"               type="integer">50000000</variable>
	  <variable id="buffer_server_factor_size" type="integer">2</variable>
	  <variable id="info_level"                type="integer">1</variable>
      <variable id="using_server" type="bool">$using_server</variable>
      <variable id="using_oasis" type="bool">$using_oasis</variable>
	  <variable id="oasis_codes_id"            type="string" >oceanx</variable>
	
      </variable_definition>
               
  </context>
  
</simulation>
EOF
