#!/bin/bash

source config.cfg #REMOVE

#DIALOGRC=/SCR/skaiser/BA/scripts_BA/dialogrc

diacnf_width=50
diacnf_height=20
     
#MOVE TO main.sh
function tabulator(){
a=0
}
         
function navigation(){
	
	case $1 in 	next) A_navigation+=($2);;
							back) unset A_navigation[-1]
										fkt_navigation=${A_navigation[-1]}
										unset A_navigation[-1];;
	esac
}




function dia_mainmenu(){
	navigation next $FUNCNAME
	
	dia_mainmenu1=`\
	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--help-button --help-label "Hilfe" \
					--ok-label "Weiter" \
					--cancel-label "Beenden" \
					--menu "Hauptmenü" $diacnf_height $diacnf_width 3\
		         1 "Aufnahme" \
		         2 "Profile" \
		         3 "Optionen" 3>&1 1>&2 2>&3`
		      
		
	case "$dia_mainmenu1" in 	1) dia_1;;
														2) dia_2;;
														3) dia_3;; 
	esac            
}

#-----------------------------------------------------------

function dia_1(){
	navigation next $FUNCNAME
	
	str_config=""
	for i in ${!rec_config[*]}; do
			str_config+="${rec_config[$i]}: ${rec_default[$i]}\n"
	done
	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--yes-label "Weiter" \
					--no-label "Zurück" \
					--yesno	"Aktuelles Profil:\n\n$str_config" \
					$diacnf_height $diacnf_width
	case $? in 	0) dia_1_1;;
							1) navigation back && $fkt_navigation;;
	esac 
}

function dia_2(){
	navigation next $FUNCNAME
	dia_profilmenu1=`\
	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--help-button --help-label "Hilfe" \
					--ok-label "Weiter" \
					--cancel-label "Beenden" \
					--menu "Aufnahme-Profile verwalten" $diacnf_height $diacnf_width 3\
		         1 "Neues Profil" \
		         2 "Profil laden" \
		         3 "Profil löschen" 3>&1 1>&2 2>&3`
		      
		
	case "$dia_profilmenu1" in 	1) dia_2_1;;
															2) dia_2_2;;
															3) dia_2_3;; 
	esac
}

function dia_3(){
	navigation next $FUNCNAME
	
	dialog --yes-label "Weiter" \
					--no-label "Zurück" \
					--yesno	"menu 3" \
					$diacnf_height $diacnf_width
	case $? in 	0) dia_3_1;;
							1) navigation back && $fkt_navigation;;
	esac 
}

function dia_4(){
	navigation next $FUNCNAME
	
	dialog --yes-label "Weiter" \
					--no-label "Zurück" \
					--yesno	"menu 4" \
					$diacnf_height $diacnf_width
	case $? in 	0) dia_4_1;;
							1) navigation back && $fkt_navigation;;
	esac 
}

#-----------------------------------------------------------

function dia_1_1(){
	navigation next $FUNCNAME

	dialog --yes-label "Start" \
					--no-label "Zurück" \
					--yesno	"Aufnahme Starten" \
					$diacnf_height $diacnf_width
	case $? in 	0) dia_1_1_1;;
							1) navigation back && $fkt_navigation;;
	esac 
}

function dia_2_1(){
	navigation next $FUNCNAME

	A_newprofil=()
	#dia_profilmenu1=`\
	dialog --backtitle "MSC-Tools | Lecture Recording" \
					--ok-label "Speichern" \
					--cancel-label "Abbrechen" \
					--title "newprofil" \
					--form "Neues Profil anlegen" $diacnf_height $diacnf_width 5 \
						"Profil-Name:"			1 1 "${A_newprofil[0]}" 1 10 20 0 \
						"Sound-Treiber:"		1 1	"${A_newprofil[1]}" 2 10 20 0 \
						"Sounds-Hardware:"	2 1	"${A_newprofil[2]}" 3 10 20 0 \
						"Audio-Encoder:"		3 1	"${A_newprofil[3]}" 4 10 20 0 \
						"Video-Encoder:"		4 1	"${A_newprofil[4]}" 5 10 20 0 \
						"Layout-Vorlage:"		5 1 "${A_newprofil[5]}" 6 10 20 0 \
						"Datei-Name:"      	6 1 "${A_newprofil[6]}" 7 10 20 0 #2>&1 1>&3`
}
#-----------------------------------------------------------

function dia_1_1_1(){
	navigation next $FUNCNAME

	dialog --yes-label "Stop" \
					--no-label "Neue Aufnahme" \
					--yesno	"Aufnahme stoppen" \
					$diacnf_height $diacnf_width
	case $? in 	0) dia_1_1;;
							1) navigation back && $fkt_navigation;;
	esac 
}

dia_mainmenu
