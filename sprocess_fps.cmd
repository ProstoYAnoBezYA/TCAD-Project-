#set PhosTop  -3.5556786
#set PhosBot  -2.9999995
#set BorTop   -3.5557716
#set BorBot   -2.9999995

##header 
##set DEBUG 1
##endheader

#AdvancedCalibration
AdvancedCalibration 2017.09
source ./AdvCal_DCKristal.fps
#math coord.ucs

math numThreads=4

#----------------------------------------------------------------------#
mgoals on min.normal.size= @norm@<nm> accuracy= @mgo@<nm> \
       normal.growth.ratio= @rat@ 
#----------------------------------------------------------------------#
line x   location= 0.0    spacing= @spa@   tag= sibot
line x   location= @substr_thick@ spacing= @spa@   tag= sitop
line y   location= @left_border@    spacing= @spa@   tag= left
line y   location= @right_border@  spacing= @spa@   tag= right
pdbSet Grid Adaptive 1

region   substrate silicon xlo= sibot xhi= sitop ylo= left yhi= right field= Phosphorus resistivity= @substr_res@
init field= Phosphorus resistivity= 1.0 !DelayFullD
#----------------------------------------------------------------------#
pdbSet Mechanics StressHistory 1
pdbSet Silicon Phosphorus DiffModel @DiffModel@
pdbSet Silicon Boron DiffModel @DiffModel_Boron@
#split @1_Epitaxy@ 
deposit material= Si3N4 thickness=@Saphire_thickness@
temp_ramp name= t1 temperature= 550 t.final= 700 time= 1<min>
#temp_ramp name= t1 t.final= 700 time= 5<min> Epi thick= @epi_thick@<um> \
# epi.doping= {Boron= 3e16}
#epi.resist= { Phosphorus= 4.5 }
#diffuse temp.ramp= t1
deposit material= Silicon type= isotropic thickness= @epi_thick@ \
fields.values= {Phosphorus= 1.031e15 }
temp_ramp name= Start_Annealing time= 10 temperature= 700 flowN2= 5
diffuse temp_ramp= Start_Annealing
struct smesh= n@node@


#split @48_Oxidation@
temp_ramp name= Oxidation48 time= 5 temperature= @drive_in_temp@ N2
temp_ramp name= Oxidation48 time= (850-@drive_in_temp@)/@ramp_up@ temperature= @drive_in_temp@ t.final= 850 flowN2= 5
temp_ramp name= Oxidation48 time= 500 temperature= 850 flowO2= 5
temp_ramp name= Oxidation48 time= 28 temperature= 850 flowO2= 5 flowH2= 8
temp_ramp name= Oxidation48 time= (850-@drive_in_temp@)/@ramp_up@ temperature= 850 t.final= @drive_in_temp@ flowN2= 10
temp_ramp name= Oxidation48 time= 5 temperature= @drive_in_temp@ N2
diffuse temp_ramp= Oxidation48
struct smesh= n@node@

#split @50_Photo_II@
#if @NMOS@==1
#mask     name= mask2 segments= {-2 -1} negative
#photo    mask= mask2 thickness= 1
#endif
#if @PMOS@==1
mask     name= mask2 segments= {@left_border@ @right_border@} negative
photo    mask= mask2 thickness= 1
#endif
struct smesh= n@node@

#split @52_B_doping_I@
implant species= Boron Silicon pearson
implant energy= @E_Pocket@<keV> dose= @Dose_Pocket@/4<cm-2> tilt= @tilt@<degree> rotation=0<degree> Boron
implant energy= @E_Pocket@<keV> dose= @Dose_Pocket@/4<cm-2> tilt= @tilt@<degree> rotation=90<degree> Boron
implant energy= @E_Pocket@<keV> dose= @Dose_Pocket@/4<cm-2> tilt= @tilt@<degree> rotation=180<degree> Boron
implant energy= @E_Pocket@<keV> dose= @Dose_Pocket@/4<cm-2> tilt= @tilt@<degree> rotation=270<degree> Boron
struct smesh= n@node@

#split @52_B_doping_II@
implant species= Boron Silicon pearson
implant energy= @E_Pocket2@<keV> dose= @Dose_Pocket2@/4<cm-2> tilt= @tilt@<degree> rotation=0<degree> Boron
implant energy= @E_Pocket2@<keV> dose= @Dose_Pocket2@/4<cm-2> tilt= @tilt@<degree> rotation=90<degree> Boron
implant energy= @E_Pocket2@<keV> dose= @Dose_Pocket2@/4<cm-2> tilt= @tilt@<degree> rotation=180<degree> Boron
implant energy= @E_Pocket2@<keV> dose= @Dose_Pocket2@/4<cm-2> tilt= @tilt@<degree> rotation=270<degree> Boron
struct smesh= n@node@

#split @53_PR_Strip_II@
strip    Photoresist
struct smesh= n@node@

#split @56_Photo_III@
#if @PMOS@==1
mask     name= mask3 segments= {(@right_border@+@left_border@)/2.0-@channel_len@/2.0 (@right_border@+@left_border@)/2.0+@channel_len@/2.0} negative
photo    mask= mask3 thickness= 1
#endif
#if @NMOS@==1
mask     name= mask3 segments= {@left_border@ @right_border@} negative
photo    mask= mask3 thickness= 1
#endif
struct smesh= n@node@

#split @59_B_doping@
implant species= Boron Silicon pearson
implant energy= @E_P_SD@<keV> dose= @Dose_P_SD@/4<cm-2> tilt= @tilt@<degree> rotation=0<degree> Boron
implant energy= @E_P_SD@<keV> dose= @Dose_P_SD@/4<cm-2> tilt= @tilt@<degree> rotation=90<degree> Boron
implant energy= @E_P_SD@<keV> dose= @Dose_P_SD@/4<cm-2> tilt= @tilt@<degree> rotation=180<degree> Boron
implant energy= @E_P_SD@<keV> dose= @Dose_P_SD@/4<cm-2> tilt= @tilt@<degree> rotation=270<degree> Boron
struct smesh= n@node@

#split @60_PR_Strip_III@
strip    Photoresist
struct smesh= n@node@

#split @64_Oxide_etch@
etch     material= {Oxide} rate= 0.05 time= 1 type= anisotropic
struct smesh= n@node@

#split @66_Oxidation@
temp_ramp name= Oxidation66 time= 5 temperature= @drive_in_temp@ N2
temp_ramp name= Oxidation66 time= (850-@drive_in_temp@)/@ramp_up@ temperature= @drive_in_temp@ t.final= 850 flowN2= 5
temp_ramp name= Oxidation66 time= 14 temperature= 850 flowO2= 5 flowH2= 8
temp_ramp name= Oxidation66 time= (850-@drive_in_temp@)/@ramp_up@ temperature= 850 t.final= @drive_in_temp@ flowN2= 10
temp_ramp name= Oxidation66 time= 5 temperature= @drive_in_temp@ N2
diffuse temp_ramp= Oxidation66
struct smesh= n@node@

#split @68_Polysi_depo@
deposit material= Poly type= isotropic thickness= 0.575
struct smesh= n@node@

#split @70_Phosphorus_diffusion@
deposit material= Poly type= isotropic thickness= 0.55 \
fields.values= {Phosphorus= 2.5e20 }

temp_ramp name= Annealing1 time= 5 temperature= @drive_in_temp@ N2
temp_ramp name= Annealing1 time= (850-@drive_in_temp@)/@ramp_up@ temperature= @drive_in_temp@ t.final= 850 flowN2= 5
temp_ramp name= Annealing1 time= 20 temperature= 850 flowN2= 5
temp_ramp name= Annealing1 time= (850-@drive_in_temp@)/@ramp_up@ temperature= 850 t.final= @drive_in_temp@ flowN2= 10
temp_ramp name= Annealing1 time= 5 temperature= @drive_in_temp@ N2
diffuse temp_ramp= Annealing1
struct smesh= n@node@

#split @71_PSG_etch@
etch     material= {Poly} rate= 0.55 time= 1 type= anisotropic
struct smesh= n@node@

#split @72_Rs_measure@
diffuse time= 0.0 temperature= 850
SheetResistance x= 0.1
struct smesh= n@node@

#split @74_Photo_IV@
mask     name= mask4 segments= {(@right_border@+@left_border@)/2.0-@gate_len@/2.0 (@right_border@+@left_border@)/2.0+@gate_len@/2.0} negative
photo    mask= mask4 thickness= 1
struct smesh= n@node@

#split @78_Polysi_etch@
etch     material= {Poly} rate= 0.58 time= 1 type= anisotropic
struct smesh= n@node@

#split @81_PR_Strip_IV@
strip    Photoresist
struct smesh= n@node@

#split @86_Oxidation@
temp_ramp name= Oxidation86 time= 5 temperature= @drive_in_temp@ N2
temp_ramp name= Oxidation86 time= (850-@drive_in_temp@)/@ramp_up@ temperature= @drive_in_temp@ t.final= 850 flowN2= 5
#temp_ramp name= Oxidation86 time= 60 temperature= 850 flowO2= 5
temp_ramp name= Oxidation86 time= 15 temperature= 850 flowO2= 5 flowH2= 8
temp_ramp name= Oxidation86 time= (850-@drive_in_temp@)/@ramp_up@ temperature= 850 t.final= @drive_in_temp@ flowN2= 10
temp_ramp name= Oxidation86 time= 5 temperature= @drive_in_temp@ N2
diffuse temp_ramp= Oxidation86
struct smesh= n@node@

#split @88_Photo_V@
#if @NMOS@==1
mask     name= mask5 segments= {(@right_border@+@left_border@)/2.0-@channel_len@/2.0 (@right_border@+@left_border@)/2.0+@channel_len@/2.0} negative
photo    mask= mask5 thickness= 1
#endif
#if @PMOS@==1
mask     name= mask5 segments= {@left_border@ @right_border@} negative
photo    mask= mask5 thickness= 1
#endif
struct smesh= n@node@

#split @91_P_doping@
implant species= Phosphorus Silicon pearson
implant energy= @N_SD_Energy@<keV> dose= @N_SD_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=0<degree> Phosphorus
implant energy= @N_SD_Energy@<keV> dose= @N_SD_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=90<degree> Phosphorus
implant energy= @N_SD_Energy@<keV> dose= @N_SD_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=180<degree> Phosphorus
implant energy= @N_SD_Energy@<keV> dose= @N_SD_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=270<degree> Phosphorus
struct smesh= n@node@

#split @92_PR_Strip_V@
strip    Photoresist
struct smesh= n@node@

#split @95_Photo_VI@
#if @PMOS@==1
mask     name= mask6 segments= {(@right_border@+@left_border@)/2.0-@channel_len@/2.0+@LDD_overlap@ (@right_border@+@left_border@)/2.0+@channel_len@/2.0-@LDD_overlap@} negative
photo    mask= mask6 thickness= 1
#endif
#if @NMOS@==1
mask     name= mask6 segments= {@left_border@ @right_border@} negative
photo    mask= mask6 thickness= 1
#endif
struct smesh= n@node@

#split @99_B_doping@
implant species= Boron Silicon pearson
implant energy= @P_Dostroi_Energy@<keV> dose= @P_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=0<degree> Boron
implant energy= @P_Dostroi_Energy@<keV> dose= @P_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=90<degree> Boron
implant energy= @P_Dostroi_Energy@<keV> dose= @P_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=180<degree> Boron
implant energy= @P_Dostroi_Energy@<keV> dose= @P_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=270<degree> Boron
struct smesh= n@node@

#split @100_PR_Strip_VI@
strip    Photoresist
struct smesh= n@node@

#split @103_Photo_VII@
#if @NMOS@==1
mask     name= mask7 segments= {(@right_border@+@left_border@)/2.0-@channel_len@/2.0+@LDD_overlap@ (@right_border@+@left_border@)/2.0+@channel_len@/2.0-@LDD_overlap@} negative
photo    mask= mask7 thickness= 1
#endif
#if @PMOS@==1
mask     name= mask7 segments= {@left_border@ @right_border@} negative
photo    mask= mask7 thickness= 1
#endif
struct smesh= n@node@

#split @106_P_doping@
implant species= Phosphorus Silicon pearson
implant energy= @N_Dostroi_Energy@<keV> dose= @N_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=0<degree> Phosphorus
implant energy= @N_Dostroi_Energy@<keV> dose= @N_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=90<degree> Phosphorus
implant energy= @N_Dostroi_Energy@<keV> dose= @N_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=180<degree> Phosphorus
implant energy= @N_Dostroi_Energy@<keV> dose= @N_Dostroi_Dose@/4<cm-2> tilt= @tilt@<degree> rotation=270<degree> Phosphorus
struct smesh= n@node@

#split @108_PR_Strip_VII@
strip    Photoresist
struct smesh= n@node@

#split @112_TEOS_depo@
deposit material= Oxide type= isotropic thickness= 0.2
struct smesh= n@node@

#split @114_Photo_VIII@
#mask     name= mask8 segments= {@left_border@ @right_border@} negative
#photo    mask= mask8 thickness= 1
struct smesh= n@node@

#split @117_Oxide_etch@
etch     material= {Oxide} rate= 0.23 time= 1 type= anisotropic
struct smesh= n@node@

#split @125_PR_Strip_VIII@
strip    Photoresist
struct smesh= n@node@

#split @129_Annealing@

#pdbSet Si Phosphorus Vac D { 0 {[Arrhenius 0.0083 3.482]} -1 {[Arrhenius 0.029 3.647]} -2 {[Arrhenius 5.88e-5 2.9]}}
#pdbSet Si Phosphorus Int D { 0 {[Arrhenius 1.2*0.6 3.482]} -1 {[Arrhenius 1.2*1.0 3.647]}}

temp_ramp name= Annealing2 time= 5 temperature= @drive_in_temp@ N2
temp_ramp name= Annealing2 time= (850-@drive_in_temp@)/@ramp_up@ temperature= @drive_in_temp@ t.final= 850 flowN2= 5
temp_ramp name= Annealing2 time= 60 temperature= 850 flowN2= 5
temp_ramp name= Annealing2 time= (850-@drive_in_temp@)/@ramp_up@ temperature= 850 t.final= @drive_in_temp@ flowN2= 10
temp_ramp name= Annealing2 time= 5 temperature= @drive_in_temp@ N2
diffuse temp_ramp= Annealing2
struct smesh= n@node@

#split @130_Nitride_depo@
deposit material= Nitride type= isotropic thickness= 0.13
struct smesh= n@node@

#split @132_Photo_IX@
#mask     name= mask9 segments= {@left_border@ @right_border@} negative
#photo    mask= mask9 thickness= 1
struct smesh= n@node@

#split @134_Nitride_etch@
etch     material= {Nitride} rate= 0.14 time= 1 type= anisotropic
struct smesh= n@node@

#split @137_PR_Strip_IX@
strip    Photoresist
struct smesh= n@node@

#split @Metallization@
#deposit material= Aluminum type= isotropic thickness= 0.5
mask     name= maskmet3 segments= {(@right_border@+@left_border@)/2.0-@channel_len@/2.0-0.5 (@right_border@+@left_border@)/2.0+@channel_len@/2.0+0.5} negative
photo    mask= maskmet3 thickness= 1
etch     material= {Oxide} rate= 0.1 time= 1 type= anisotropic
strip    Photoresist

contact name= "Drain" box Si xlo= -1*@Saphire_thickness@-@epi_thick@+0.04 xhi= -1*@Saphire_thickness@-@epi_thick@  ylo= @left_border@ yhi= (@right_border@+@left_border@)/2.0-@channel_len@/2.0-0.5

contact name= "Source" box Si xlo= -1*@Saphire_thickness@-@epi_thick@+0.04 xhi= -1*@Saphire_thickness@-@epi_thick@  ylo= (@right_border@+@left_border@)/2.0+@channel_len@/2.0+0.5 yhi= @right_border@

contact name= "Gate" box Poly xlo= -1*@Saphire_thickness@-@epi_thick@-0.57 xhi= -1*@Saphire_thickness@-@epi_thick@-0.59  ylo= (@right_border@+@left_border@)/2.0-@gate_len@/2.0 yhi= (@right_border@+@left_border@)/2.0+@gate_len@/2.0

contact name= "Substrate" bottom
struct mshcmd smesh= n@node@

struct tdr=n@node@_fps

exit


