# source file for color text output

BRONZE="\033[33m"
YELLOW="\e[33m"
GREEN="\033[32m"
GRAY="\033[37m"
CYAN="\e[36m"
RED="\e[31m"
RESET="\e[0m"
BOLD="\e[1m"


function EchoGreen {
  echo -e "$GREEN $1 $GRAY"
}

function EchoRed {
  echo -e "$RED $1 $RESET"
}
