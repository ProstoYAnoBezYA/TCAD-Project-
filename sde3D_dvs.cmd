;--------------------------------------------
;Defining Variables
 
(define Hil	@Tox@e-3) 	;  41
(define Hsub	0.8)		; 
(define Hsub1	1.7)		; 
(define Htin	25e-3)		; 	
 
(define Lsd	@Lsd@e-3)		; 
 
(define Lc	@Lch@e-3)		; 
(define Hfet	@Hfet@)		; 
(define Hsd	@Hsd@e-3)		; 
(define Lsp	0e-3)		; 
 
(define Lall	(+ Lc (* 2 Lsd) (* 2 Lsp)))	; 
(define Wsub	@Width@)
(define Wsubext	@Wsubext@e-3)	
(define Wsub2	(+ Wsub Wsubext Wsubext))	
 
(define Wsubext2	Wsubext)
;------------------------------------------------------------------------
;Creating Structure
 
(sdegeo:create-cuboid (position (- Wsubext) (- 0 Wsubext (/ Wsub 2)) 0) (position (+ Lall Wsubext) (+ Wsubext (/ Wsub 2)) (+ Hsub)) 
"Insulator" "Ox_Substrate")
 
(sdegeo:create-cuboid (position (- Wsubext) (- 0 Wsubext (/ Wsub 2)) Hsub) (position (+ Lall Wsubext) (+ Wsubext (/ Wsub 2)) (+ Hsub Hfet)) 
"SiO2" "SiO2_Pocket")
 
(sdegeo:create-cuboid (position 0 (- 0 (/ Wsub 2)) Hsub) (position (+ Lall) (+ (/ Wsub 2)) (+ Hsub Hfet)) 
"Silicon" "FET")
 
(sdegeo:create-cuboid (position (+ Lsd Lsp) (- 0 Wsubext2 (/ Wsub 2)) (+ Hsub Hfet)) (position (- Lall (+ Lsd Lsp)) (+ Wsubext2 (/ Wsub 2)) (+ Hsub Hfet Hil)) 
"SiO2" "MOS_IL")
 
(sdegeo:create-cuboid (position (+ Lsd Lsp) (- 0 Wsubext2 (/ Wsub 2)) (+ Hsub Hfet Hil  )) (position (- Lall (+ Lsd Lsp)) (+ Wsubext2 (/ Wsub 2)) (+ Hsub Hfet Hil   Htin)) 
"PolySi" "MOS_ME")
 
(sdegeo:create-cuboid (position 0 (- (/ Wsub 2)) (+ Hsub Hfet)) (position Lsd (+ (/ Wsub 2)) (+ Hsub Hfet Htin)) 
"TiN" "Source_Me")
 
(sdegeo:create-cuboid (position Lall (- (/ Wsub 2)) (+ Hsub Hfet)) (position (- Lall Lsd) (+ (/ Wsub 2)) (+ Hsub Hfet Htin)) 
"TiN" "Drain_Me")
 
 
;--------------------------------------
;Defining Profile
 
(sdedr:define-constant-profile "Substrate_Definition" "PhosphorusActiveConcentration" @Nsub@)
(sdedr:define-constant-profile-region "Substrate_Place" "Substrate_Definition" "Substrate" 0 "LocalReplace")
(sdedr:define-constant-profile-region "Substrate2_Place" "Substrate_Definition" "Substrate2" 0 "LocalReplace")
(sdedr:define-constant-profile-region "FET_Place" "Substrate_Definition" "FET" 0 "LocalReplace")
(sdedr:define-constant-profile-region "SD_Source_Place" "Substrate_Definition" "SD_Source" 0 "LocalReplace")
(sdedr:define-constant-profile-region "SD_Drain_Place" "Substrate_Definition" "SD_Drain" 0 "LocalReplace")
 
(sdedr:define-constant-profile "PolySi_Definition" "PhosphorusActiveConcentration" 2e20) ;2e19
(sdedr:define-constant-profile-region "PolySi_Place" "PolySi_Definition" "MOS_Polysi" 0 "LocalReplace")
 

(define p_plx_path "n@previous@_@DiffModel@_@DiffModel_Boron@_PActive.plx")
(define b_plx_path "n@previous@_@DiffModel@_@DiffModel_Boron@_BActive.plx")
 

(sdedr:define-1d-external-profile
  "SD_Definition"
  p_plx_path
  "Scale" 1.0
  "DataScale" 1.0
  "Range" @PhosTop@ @PhosBot@

;"Gauss" "StdDev" 0.015) 
"Gauss" "Factor" 0.2)

(sdedr:define-1d-external-profile
  "Spacer_Definition"
  p_plx_path
  "Scale" 1.0
  "DataScale" 1.0
  "Range" @PhosTop@ @PhosBot@

;   "Gauss" "StdDev" 0.015)  
"Gauss" "Factor" 0.2)

(sdedr:define-1d-external-profile
  "Pocket_Definition"
  b_plx_path
  "Scale" 1.0
  "DataScale" 1.0
;  "Range" @BorTop@ @BorBot@
"Range" @BorTop@  -2.950000
;  "Gauss" "Factor" 0.8)                  
 "Gauss" "Factor" 0.0)
 
(sdedr:define-constant-profile "MOS_ME_Definition" "PhosphorusActiveConcentration" 2e20)
(sdedr:define-constant-profile-region "MOS_ME_Place" "MOS_ME_Definition" "MOS_ME" 0 "Replace")
 
(sdedr:define-refeval-window "Source_Window" "Rectangle" (position 0 (- (/ Wsub 2)) (+ Hsub Hfet)) (position Lsd (+ (/ Wsub 2)) (+ Hsub Hfet)))
(sdedr:define-refeval-window "Drain_Window" "Rectangle" (position Lall (- (/ Wsub 2)) (+ Hsub Hfet)) (position (- Lall Lsd) (+ (/ Wsub 2)) (+ Hsub Hfet)))
 
(sdedr:define-refeval-window "Spacer1_Window" "Rectangle" (position (+ 0) (- (/ Wsub 2)) (+ Hsub Hfet)) (position (+ Lsd Lsp) (+ (/ Wsub 2)) (+ Hsub Hfet)))	
(sdedr:define-refeval-window "Spacer2_Window" "Rectangle" (position (- Lall 0) (- (/ Wsub 2)) (+ Hsub Hfet)) (position (- Lall (+ Lsd Lsp)) (+ (/ Wsub 2)) (+ Hsub Hfet)))	
 
(sdedr:define-refeval-window "Pocket_Window" "Rectangle" (position (- Wsubext) (- 0 Wsubext (/ Wsub 2)) (+ Hsub Hfet)) (position (+ Lall Wsubext) (+ Wsubext (/ Wsub 2)) (+ Hsub Hfet)))
 
;(sdedr:define-analytical-profile-placement
;  "Source_Place" "SD_Definition" "Source_Window"
;  "Negative" "Replace" "Eval")
 
;(sdedr:define-analytical-profile-placement
;  "Drain_Place" "SD_Definition" "Drain_Window"
;  "Negative" "Replace" "Eval")
 
;(sdedr:define-analytical-profile-placement
;  "Spacer1_Place" "Spacer_Definition" "Spacer1_Window"
;  "Negative" "Replace" "Eval")
 
;(sdedr:define-analytical-profile-placement
;  "Spacer2_Place" "Spacer_Definition" "Spacer2_Window"
;  "Negative" "Replace" "Eval")
 
;(sdedr:define-analytical-profile-placement
;  "Pocket_Place" "Pocket_Definition" "Pocket_Window"
;  "Negative" "Replace" "Eval")
(sdedr:define-analytical-profile-placement
  "Source_Place"  "SD_Definition"     "Source_Window"  "Negative" "NoReplace" "Eval")
(sdedr:define-analytical-profile-placement
  "Drain_Place"   "SD_Definition"     "Drain_Window"   "Negative" "NoReplace" "Eval")
;(sdedr:define-analytical-profile-placement
;  "Spacer1_Place" "Spacer_Definition" "Spacer1_Window" "Negative" "NoReplace" "Eval")
;(sdedr:define-analytical-profile-placement
;  "Spacer2_Place" "Spacer_Definition" "Spacer2_Window" "Negative" "NoReplace" "Eval")
(sdedr:define-analytical-profile-placement
  "Pocket_Place"  "Pocket_Definition" "Pocket_Window"  "Negative" "NoReplace" "Eval") 

 
;--------------------------------------
;Defining Mesh
 
(sdedr:define-refeval-window "AllMesh_Window" "Cuboid" (position (- Wsubext) (- 0 Wsubext (/ Wsub 2)) (- Hsub1)) (position (+ Lall Wsubext) (+ Wsubext (/ Wsub 2)) (+ Hsub Hfet)))
 
 
(sdedr:define-refeval-window "SourceMesh_Window" "Cuboid" (position 0 (- (/ Wsub 2)) (+ Hsub Hfet)) (position (* 1.8 Lsd) (+ (/ Wsub 2)) (- (+ Hsub Hfet) Hsd)))
(sdedr:define-refeval-window "DrainMesh_Window" "Cuboid" (position Lall (- (/ Wsub 2)) (+ Hsub Hfet)) (position (- Lall (* 1.8 Lsd)) (+ (/ Wsub 2)) (- (+ Hsub Hfet) Hsd)))
 
(sdedr:define-refeval-window "Spacer1Mesh_Window" "Cuboid" (position 0 (- (/ Wsub 2)) (+ Hsub Hfet)) (position (+ Lsd (* 1.8 Lsp)) (+ (/ Wsub 2)) (- (+ Hsub Hfet) (/ Hsd 10))))
(sdedr:define-refeval-window "Spacer2Mesh_Window" "Cuboid" (position (- Lall 0) (- (/ Wsub 2)) (+ Hsub Hfet)) (position (- Lall Lsd (* 1.8 Lsp)) (+ (/ Wsub 2)) (- (+ Hsub Hfet) (/ Hsd 4))))
 
(sdedr:define-refinement-size "AllMesh_Definition"  (/ Lc 5) (/ Wsub2 16) (/ Hsub1 10) (/ Lc 20) (/ Wsub2 20) (/ Hsub1 30))
(sdedr:define-refinement-function "AllMesh_Definition" "DopingConcentration" "MaxTransDiff" 1)
 
(sdedr:define-refinement-size "SDMesh_Definition"  (/ Lsd 3) (/ Wsub 3) (/ Hsd 3) (/ Lsd 25) (/ Wsub 25) (/ Hsd 20))
(sdedr:define-refinement-function "SDMesh_Definition" "DopingConcentration" "MaxTransDiff" 1)
 
(sdedr:define-refinement-size "SpacerMesh_Definition"  (/ Lsd 3) (/ Wsub 3) (/ Hsd 5) (/ Lsd 25) (/ Wsub 15) (/ Hsd 20))
(sdedr:define-refinement-function "SpacerMesh_Definition" "DopingConcentration" "MaxTransDiff" 1)
 
(sdedr:define-refinement-placement "AllMesh_Place" "AllMesh_Definition" "AllMesh_Window")
(sdedr:define-refinement-placement "SourceMesh_Place" "SDMesh_Definition" "SourceMesh_Window")
(sdedr:define-refinement-placement "DrainMesh_Place" "SDMesh_Definition" "DrainMesh_Window")
 
(sdedr:define-refinement-placement "Spacer1Mesh_Place" "SpacerMesh_Definition" "Spacer1Mesh_Window")
(sdedr:define-refinement-placement "Spacer2Mesh_Place" "SpacerMesh_Definition" "Spacer2Mesh_Window")
 
;-------------------------------------------------
; Defining Contacts
 
(sdegeo:define-contact-set "Source" 4 (color:rgb 1 0 0) "##")
(sdegeo:set-contact (find-face-id (position (/ Lsd 2) 0 (+ Hsub Hfet Htin))) "Source")
 
(sdegeo:define-contact-set "Drain" 4 (color:rgb 0 1 0) "solid")
(sdegeo:set-contact (find-face-id (position (- Lall (/ Lsd 2)) 0 (+ Hsub Hfet Htin))) "Drain")
 
(sdegeo:define-contact-set "Gate" 4 (color:rgb 0 0 1) "solid")
(sdegeo:set-contact (find-face-id (position (/ Lall 2) 0 (+ Hsub Hfet Hil   Htin))) "Gate")
 
(sdegeo:define-contact-set "Sub" 4 (color:rgb 0 0 1) "solid")
(sdegeo:set-contact (find-face-id (position (/ Lall 2) 0 0)) "Sub")
 
 
;--------------------------------------------
 ; Meshing structure 
(sde:build-mesh "snmesh" "" "n@node@_msh")