#Add external content
. ~/.profile

#Color Preferences
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
#Orange Prompt: PS1='\[\e[0;33m\]\h:\W \u\$\[\e[m\] '
PS1="\[\033[35m\]\t\[\033[m\]-\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "

#Utility commands
alias eb='vim ~/.bashrc'
alias sb='source ~/.bashrc'
alias testrdp="sudo nmap -p3389 -P0 -sS "
alias testssl="sudo nmap -p443 -P0 -sS "

#'Stroke' portscan built into macos
alias stroke="/System/Library/CoreServices/Applications/Network\ Utility.app/Contents/Resources/stroke"

alias mate='open -a TextMate '

#####
# Server Alias
#####
#Remote
alias digitalocean='ssh $digitaloceanip'

#Local
alias p1='ssh -p 1234 $pietyip'
alias linuxvmlan='ssh $linuxvmlanip'
alias macremote='ssh $maclanip'
