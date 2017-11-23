#!/bin/bash

rootcheck(){ #Função para descobrir o nível de autoridade do usuário
isroot=0 #Define a variável para descobrir se o usuário é ROOT
usercheck=$(whoami) #Guarda o nome do usuário na variável usercheck
if [ "$usercheck" = root ]; then #se a variável tiver o valor root...
isroot=1 #Variável isroot é definida como ativa, ou seja, é root
dialog --title "Permissões de root" --msgbox "Seu usuário é root. Você terá permissões especiais." 0 0 #Indica ao usuário que está como root
fi
}

nmonfunc(){ #Função para monitorar os componentes
    dialog --title 'Monitorar os componentes do computador'                   \
    --msgbox "Será utilizado um programa externo. Pressione Q ou CTRL + C para retornar." 0 0 #Informa o usuário de como fechar o programa externo
    nmoncmd=$(dialog --stdout --title 'Monitorar os componentes. Use ESPAÇO para selecionar'    \
    --checklist "Quais componentes você quer monitorar?" 0 0 0                                  \
    c "CPU" off                                            					\
    m "Memória Principal" off                                    				\
    d "Disco" off) #Deixa o usuário selecionar quais componentes quer monitorar
    export NMON=$nmoncmd #Dá ao programa externo os parâmetros escolhidos pelo usuário
    if [[ -n $nmoncmd ]]; then #finalmente, abrimos o programa externo com os parâmetros
        export NMON="$nmoncmd" 
        nmon
    fi
    menu
}

processos(){ #menu para administração dos processos
    clear #limpa a tela
    proccmd=$(dialog --stdout --title 'Gerenciamento de processos' --menu "Selecione a opção:" 0 0 0 \
    1 "Listar em tempo real"                                           				     \
    2 "Listar somente uma vez"                                                                       \
    3 "Prioridades"                                                                                  \
    4 "Matar processos"                                                                              \
    0 "Voltar") #Dá as opções sobre os processos
        case $proccmd in
       1) processostemporeal;menu ;;
             2) processosumavez;menu  ;;
        3) prioriexec ;;
        4) killprocessos ;;
        0) menu ;;
    esac
}

processostemporeal(){ #Lista os processos em tempo real na tela.
    dialog --msgbox "Listando Processos em tempo real. Para sair, use CTRL + C." 0 0 #Explica para o usuário como sair dos programas externos
    if [ $isroot = 1 ]; then #Se for root, abre o top normalmente listando todos os processos, se não for, abrirá somente os processos daquele usuário
        top
    else
        top -u "$USER"
    fi
}

processosumavez(){ #Lista os processos somente uma vez na tela.
    if [ $isroot = 1 ]; then #Se for root, abre o ps aux normalmente listando todos os processos, se não for, abrirá somente os processos daquele usuário
        ps aux | less
    else
        ps aux | less | grep "$USER"
    fi
    read -p "Pressione Enter para continuar..."
}

prioriexec(){
    pid=$(dialog --stdout --inputbox 'Digite o PID:' 0 0 ) #Pega do input do usuário o PID do processo
    prioridade=$(dialog --stdout\
    --inputbox 'Digite a prioridade do processo que deseja mudar(Entre -20 a 19)' 0 0 ) #Pega a prioridade do processo
    while [ $prioridade -gt 19 -o $prioridade -lt -20 ]
    do #Checa a prioridade do arquivo
    prioridade=$(dialog --stdout --inputbox 'Digite corretamente a prioridade (entre -20 a 19)' 0 0) 
    done
    renice $prioridade $pid #Altera a prioridade do processo
    dialog --stdout --msgbox 'Sucesso a prioridade foi mudada ' 0 0 #Mensagem avisando que foi bem sucedida
    dialog --stdout --yesno 'Deseja alterar outro processo?' 0 0
    if [ $? = 0 ]; then #Se o usuário responder que sim, volta ao começo da função
        prioriexec
    else
        processos #Retorna ao menu de processos
    fi
}


killprocessos(){ #função para enviar sinal a processos
        pid=$(dialog --stdout --inputbox 'Digite o PID:' 0 0 ) #declara variável processo id
    killpid="3" #define a variável com um valor inválido para entrar no loop
    while [ $killpid -ne 1 -a $killpid -ne 2 -a $killpid -ne 9 -a $killpid -ne 15 ]; do #loop para verificar se o input do usuário é válido
	    killpid=$(dialog --stdout --radiolist 'Escolha o sinal que deseja enviar' 0 0 0     \
            1 "Desligamento" off                                                                \
            2 "Interrupção" off                                   				\
            9 "Matar" off                                                                       \
            15 "Terminar" off                                                                   \
            0 "Voltar" off)
            if [ $killpid -eq 0 ]; then
            processos #retorna ao menu de processos
	    fi
    done
    kill $killpid $pid #manda sinal ao processo id
    dialog --stdout --yesno 'Deseja alterar outro processo?' 0 0 #prompt para o usuário se ele quer alterar outro processo
        if [ $? = 0 ]; then
                killprocessos #retorna ao começo do menu
        else
                menu #retorna ao menu principal
        fi
}

disk(){ #Função para o threshold do disco
    DISK=$(df -hT | grep ext4 | awk '{print $6}' | sed 's/[%]$//') #Pega o valor atual do componente em questão
    diskt="70" #Coloca o valor padrão de 70 para o threshold
    if [ $isroot -eq 1 ]; then #Caso for root, haverá a opção alterar o threshold
        dialog --stdout --yesno "Deseja personalizar o valor do threshold? Caso escolha não, será utilizado o valor definido pelo administrador." 0 0
        if [ $? = 0 ]; then #Caso a resposta seja sim, usará um valor personalizado. Caso não seja, utilizará um valor padrão definido previamente pelo administrador.
            diskt="100"  #coloca um valor fora do limite para entrar no loop
            while [ $diskt -lt 10 -o $diskt -gt 99 ]; do #Determina um máximo e mínimo para o threshold
                diskt=$(dialog --stdout --inputbox "Insira o valor do threshold." 0 0)
                if [ $diskt -lt 10 -o $diskt -gt 99 ]; then #Caso o valor do threshold escolhido seja menor que 10 ou maior que 99, aparecerá um aviso
                    dialog --stdout --msgbox "Insira um valor entre 10 e 99." 0 0
                fi
            done
        fi
    fi
    if [ "$DISK" -gt $diskt ]; then
        dialog --stdout --msgbox "Uso de disco acima do estipulado! (Passou de $diskt%: $DISK%)" 0 0 #Mensagem de aviso quando o componente passou do threshold
    else
        dialog --stdout --msgbox "Disco está perfeitamente normal. ($DISK%)" 0 0 #Mensagem de aviso de que o componente está em bom estado
    fi
}

mem(){ #Função para o threshold da memória
    MEM=$(free -m | grep Mem | awk '{printf "%0.f\n", $3 / $2 * 100}') #Pega o valor atual do componente em questão

        memt="70" #Coloca o valor padrão de 70 para o threshold
        if [ $isroot -eq 1 ]; then #Caso for root, haverá a opção alterar o threshold
                dialog --stdout --yesno "Deseja personalizar o valor do threshold? Caso escolha não, será utilizado o valor definido pelo administrador." 0 0
                if [ $? = 0 ]; then #Caso a resposta seja sim, usará um valor personalizado. Caso não seja, utilizará um valor padrão definido previamente pelo administrador.
                        memt="100"  #coloca um valor fora do limite para entrar no loop
                        while [ $memt -lt 10 -o $memt -gt 99 ]; do #Determina um máximo e mínimo para o threshold
                                memt=$(dialog --stdout --inputbox "Insira o valor do threshold." 0 0)
                                if [ $memt -lt 10 -o $memt -gt 99 ]; then #Caso o valor do threshold escolhido seja menor que 10 ou maior que 99, aparecerá um aviso
                                        dialog --stdout --msgbox "Insira um valor entre 10 e 99." 0 0
                                fi
                        done
                fi
        fi

        if [ "$MEM" -gt $memt ]; then #Caso a taxa de uso da memória for maior que o limite aparecerá um aviso
                dialog --stdout --msgbox "Uso de memória acima do estipulado! (Passou de $memt%: $MEM%)" 0 0 #Mensagem de aviso quando o componente passou do threshold
        else
                dialog --stdout --msgbox "Memória está perfeitamente normal. ($MEM%)" 0 0 #Mensagem de aviso de que o componente está em bom estado
    fi
}

cpu(){  #Função para o threshold da cpu
    CPU=$(top -d 1 -b -n2 | grep "Cpu(s)"|tail -n 1 | awk '{print $2 + $4}') #Pega o valor atual do componente em questão
        cput="70" #Coloca o valor padrão de 70 para o threshold
        if [ $isroot -eq 1 ]; then #Caso for root, haverá a opção alterar o threshold
                dialog --stdout --yesno "Deseja personalizar o valor do threshold? Caso escolha não, será utilizado o valor definido pelo administrador." 0 0
                if [ $? = 0 ]; then #Caso a resposta seja sim, usará um valor personalizado. Caso não seja, utilizará um valor padrão definido previamente pelo administrador.
                        cput="100" #coloca um valor fora do limite para entrar no loop
                        while [ $cput -lt 10 -o $cput -gt 99 ]; do #Determina um máximo e mínimo para o threshold
                                cput=$(dialog --stdout --inputbox "Insira o valor do threshold." 0 0)
                                if [ $cput -lt 10 -o $cput -gt 99 ]; then #Caso o valor do threshold escolhido seja menor que 70 ou maior que 99, aparecerá um aviso
                                        dialog --stdout --msgbox "Insira um valor entre 10 e 99." 0 0
                                fi
                        done
                fi
        fi

    if [ "$CPU" -gt $cput ]; then
                dialog --stdout --msgbox "Uso de CPU acima do estipulado! (Passou de $cput%: $CPU%)" 0 0 #Mensagem de aviso quando o componente passou do threshold
    else
                dialog --stdout --msgbox "CPU está perfeitamente normal. ($CPU%)" 0 0 #Mensagem de aviso de que o componente está em bom estado
    fi
}

menu(){ #Função principal, é o menu base do programa
clear #Limpa a tela
cmd=$(dialog --menu "Selecione as opções:" 0 0 0                        \
     1 'CPU'                                                \
         2 'Memória'                                            \
         3 'Disco'                                            \
         4 'Processos'                                        \
     5 'Monitorar...'                                            \
     0 'Sair' --stdout) #Dá as diversas opções relacionadas ao gerenciamento do sistema computacional
    case $cmd in
        1)  cpu #Chama a função de threshold da cpu
            menu #Volta à tela principal
            ;;
        2)  mem #Chama a função de threshold da memória
            menu #Volta à tela principal
            ;;
        3)  disk #Chama a função de threshold do disco
            menu #Volta à tela principal
            ;;
        4)  processos #Chama a função de gerenciamento de processos
        ;;
    5)  nmonfunc #Chama a função de monitorar o sistema utilizando um programa externo
         menu #Volta à tela principal
        ;;
    0)  clear #Fecha o programa
        exit 0
        ;;
    esac
}
rootcheck #chama a função rootcheck que verifica a identidade do usuário
menu #chama o corpo principal do programa
exit 0

