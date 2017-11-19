#!/bin/bash
A=0
B=0
while [ $A -lt 2 ]
do
	CPU=$(top -d 1 -b -n2 | grep "Cpu(s)"|tail -n 1 | awk '{print $2 + $4}')
	if [ $CPU -gt 80 ]; then
		B=1
	else
		B=0
	fi
if [ $B -eq 1 ]; then
        B=0
        xterm -e dialog --msgbox "Aviso: uso da CPU acima de 80% ($CPU%)" 10 20
        sleep 10
fi
done &
clear
cmd=(dialog --title "Gerenciamento do computador" --menu "Selecione as opções:" 13 30 14)
options=(1 "CPU" 
         2 "Memória" 
         3 "Disco" 
         4 "Sair" )
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
            export NMON=c
            nmon
            ;;
        2)
            export NMON=m
            nmon
            ;;
        3)
            export NMON=d
            nmon 
            ;;
        4)

            ;;
    esac
done
