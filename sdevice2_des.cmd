Device MOSFET {
Electrode {
	{ Name = "Source" Voltage = 0}# eRecVelocity = 0 hRecVelocity = 0}
	{ Name = "Drain" Voltage = 0}# eRecVelocity = 0 hRecVelocity = 0}
	{ Name = "Gate" Voltage = 0}
	{ Name = "Sub" Voltage = 0 }
}
File {
	Grid = "@tdr|sde3D@"
	Doping = "@tdr|sde3D@"
	Parameters = "@parameter@"
	Plot = "n@node@_@DiffModel@_@DiffModel_Boron@_des"
	Current = "n@node@_@DiffModel@_@DiffModel_Boron@_des"
 
*   Param = "dessis.par"
}
Physics {
#AreaFactor= @Width@
	EffectiveIntristicDensity 
	(BandGapNarrowing (Slotboom) )
	Mobility (	HighFieldSaturation*( PFMob ) * Eparallel PFMob CarrierTempDriveSpline
			PhuMob
		Enormal (
#			Lombardi
#			UniBo
		IALMob 
		Coulomb2D
		)
	CarrierCarrierScattering #(BrooksHerring) 
	DopingDependence ( 
	PhuMob 
#	BalMob (Lch = @Lch|sde1@) 
	) 
	)
	Recombination (
		SRH (DopingDependence)
		Avalanche (Lackner)#Lackner
#	Band2Band (
#		Model = Schenk #| Hurkx | E1 | E1_5 | E2 | NonlocalPath
#		DensityCorrection = Local #| None
#		InterfaceReflection #| -InterfaceReflection
#		FranzDispersion #| -FranzDispersion
#		)
	)
#	eBarrierTunneling "NLM" hBarrierTunneling "NLM"
}
Physics(MaterialInterface="Insulator/Silicon") {
	Traps(FixedCharge Level Conc= @Bottom_Charge|sdevice@ )    #0.24e12
	Recombination (SurfaceSRH)
}
Physics(RegionInterface="SiO2_Pocket/FET") {
	Traps(FixedCharge Level Conc= @Side_Charge|sdevice@ )    #0.3e12
	Recombination (SurfaceSRH)
}
Physics(RegionInterface="MOS_IL/FET") {
	Traps(FixedCharge Level Conc= @Top_Charge|sdevice@ )    #0.25e12
	Recombination (SurfaceSRH)
}
}
Plot {
	TotalCurrentDensity
   ElectrostaticPotential   
   eDensity hDensity
   eMobility hMobility eVelocity hVelocity
   Doping DonorConcentration AcceptorConcentration
   eCurrent/Vector hCurrent/Vector
   ElectricField SpaceCharge
   SRH 
}
Math { #CNormPrint
#	Nonlocal "for_tunneling" (
#		Barrier(Region="MOS_IL")
#	)
 DirectCurrent
Method = blocked
# ILS should be chosen for big 3D simulations
# For 2D, use Pardiso
Submethod=ILS(set= 5)
ILSrc= "
set (5) {
iterative(gmres(100), tolrel=1e-3, tolunprec=1e-2, tolabs=0,
maxit=200);
preconditioning(ilut(1e-9,-1), right);
ordering(symmetric=nd, nonsymmetric=mpsilst);
options(compact=yes, linscale=0, fit=5, refinebasis=1,
refineresidual=30, verbose=5);
}; "	
  Iterations= 10
  Extrapolate
  -CheckUndefinedModels
Number_of_Threads = maximum
Number_of_Solver_Threads = maximum
}
System {
    MOSFET Structure { "Source"=0 "Drain"=1 "Gate"=0 "Sub"=0 }
}
Solve {
    Coupled(Iterations=100) { Poisson }
    Coupled(Iterations=100) { Poisson Electron }
    Coupled(Iterations=100) { Poisson Electron Hole }
    QuasiStationary(
        DoZero
        InitialStep=1e-3
        MaxStep=0.02
        MinStep=1e-8
        Increment=1.3
        Decrement=2
        Goal { Contact=Structure.Drain Voltage=8 }
    )
    {
    	
        Coupled { Poisson Electron Hole }
    }
}