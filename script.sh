#!/bin/bash
root2=$(whoami)
isroot=0
if [ $root2 = root ]; then
isroot=1
dialog --msgbox "Seu usuário é ROOT. Você terá permissões especiais." 10 20
fi
B=0
disk(){
	DISK=$(df -hT | grep /dev/ | awk '{print $6}' | sed 's/[%]$//')
	if [ $DISK -gt 50 ]; then
		dialog --msgbox "Uso de disco acima de 50% ($DISK%)" 10 20
	fi
}
ram(){
	MEM=$(free -m | grep Mem | awk '{printf "%0.f\n", $3 / $2 * 100}')
        if [ $MEM -gt 1 ]; then
        	dialog --msgbox "Memória acima de 70% ($MEM%)" 10 10 
        fi
}
cpu(){
	CPU=$(top -d 1 -b -n2 | grep "Cpu(s)"|tail -n 1 | awk '{print $2 + $4}')
	if [ $CPU -gt 70 ]; then
		dialog --msgbox "Aviso: uso da CPU acima de 70% ($CPU%)" 10 20
	fi
}
menu(){
clear
cmd=(dialog --title "Gerenciamento do computador" --menu "Selecione as opções:" 13 30 14)
options=(1 "CPU" 
         2 "Memória" 
         3 "Disco" 
         4 "Processos" 
	 5 "Sair" )
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
	    cpu
            export NMON=c
            nmon; menu
            ;;
        2)
	    ram
            export NMON=m
            nmon; menu
            ;;
        3)
	    disk
            export NMON=d
            nmon; menu
            ;;
        4)
	    
	    ps aux
            ;;
	5)
	    
	    ;;
    esac
done
}
menu
exit 0
