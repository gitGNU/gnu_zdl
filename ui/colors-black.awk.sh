function init_colors () {

    ## Regular Colors
    Black="\033[0;30m"        # Nero
    Red="\033[0;31m"          # Rosso
    Green="\033[0;32m"        # Verde
    Yellow="\033[0;33m"       # Giallo
    Blue="\033[0;34m"         # Blu
    Purple="\033[0;35m"       # Viola
    Cyan="\033[0;36m"         # Ciano
    White="\033[0;37m"        # Bianco

    ## Bold
    BBlack="\033[1;30m"       # Nero
    # BRed="\033[1;31m"         # Rosso
    # BGreen="\033[1;32m"       # Verde
    # BYellow="\033[1;33m"      # Giallo
    # BBlue="\033[1;34m"        # Blu
    # BPurple="\033[1;35m"      # Viola
    # BCyan="\033[1;36m"        # Ciano
    BWhite="\033[1;37m"       # Bianco

    ## Underline
    UBlack="\033[4;30m"       # Nero
    URed="\033[4;31m"         # Rosso
    UGreen="\033[4;32m"       # Verde
    UYellow="\033[4;33m"      # Giallo
    UBlue="\033[4;34m"        # Blu
    UPurple="\033[4;35m"      # Viola
    UCyan="\033[4;36m"        # Ciano
    UWhite="\033[4;37m"       # Bianco

    ## Background
    On_Black="\033[40m"       # Nero
    On_Red="\033[41m"         # Rosso
    On_Green="\033[42m"       # Verde
    On_Yellow="\033[43m"      # Giallo
    On_Blue="\033[44m"        # Blu
    On_Purple="\033[45m"      # Purple
    On_Cyan="\033[46m"        # Ciano
    On_White="\033[47m"       # Bianco
    On_Gray1="\033[5m"        # sfondo grigio per tty
    On_Gray2="\033[100m"       # sfondo grigio per pts

    ## High Intensty
    IBlack="\033[0;90m"       # Nero
    IRed="\033[0;91m"         # Rosso
    IGreen="\033[0;92m"       # Verde
    IYellow="\033[0;93m"      # Giallo
    IBlue="\033[0;94m"        # Blu
    IPurple="\033[0;95m"      # Viola
    ICyan="\033[0;96m"        # Ciano
    IWhite="\033[0;97m"       # Bianco

    BRed="\033[40;91m"         # Rosso
    BGreen="\033[40;92m"       # Verde
    BYellow="\033[40;93m"      # Giallo
    BBlue="\033[40;94m"        # Blu
    BPurple="\033[40;95m"      # Viola
    BCyan="\033[40;96m"        # Ciano
    
    ## Bold High Intensty
    BIBlack="\033[1;90m"      # Nero
    BIRed="\033[1;91m"        # Rosso
    BIGreen="\033[1;92m"      # Verde
    BIYellow="\033[1;93m"     # Giallo
    BIBlue="\033[1;94m"       # Blu
    BIPurple="\033[1;95m"     # Viola
    BICyan="\033[1;96m"       # Ciano
    BIWhite="\033[1;97m"      # Bianco

    ## High Intensty backgrounds
    On_IBlack="\033[0;100m"   # Nero
    On_IRed="\033[0;101m"     # Rosso
    On_IGreen="\033[0;102m"   # Verde
    On_IYellow="\033[0;103m"  # Giallo
    On_IBlue="\033[0;104m"    # Blu
    On_IPurple="\033[10;95m"  # Viola
    On_ICyan="\033[0;106m"    # Ciano
    On_IWhite="\033[0;107m"   # Bianco

    ## Color_Off="\033[0m${White}${Background}"
    Color_Off="\033[0m"
}
