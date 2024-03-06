#!/bin/bash

# Check for required dependencies
if ! command -v play &>/dev/null; then
    echo "Error: The 'play' command is required but was not found. Please install 'sox'."
    exit 1
fi

# Initial configuration
FREQUENCY=1000 # Default sound frequency in Hz

# Morse Code declaration
declare -A MORSE_CODE=(
    [A]=".-" [B]="-..." [C]="-.-." [D]="-.." [E]="."
    [F]="..-." [G]="--." [H]="...." [I]=".." [J]=".---"
    [K]="-.-" [L]=".-.." [M]="--" [N]="-." [O]="---"
    [P]=".--." [Q]="--.-" [R]=".-." [S]="..." [T]="-"
    [U]="..-" [V]="...-" [W]=".--" [X]="-..-" [Y]="-.--"
    [Z]="--.." [1]=".----" [2]="..---" [3]="...--" [4]="....-"
    [5]="....." [6]="-...." [7]="--..." [8]="---.." [9]="----." [0]="-----" [" "]="/"
)

# Function to play Morse sounds
emit_sound() {
    local symbol="$1"
    local duration=0.1 # Default duration for 'dit'
    [[ "$symbol" == "-" ]] && duration=0.3 # Ensure 'dah' has correct duration
    play -n synth "$duration" sine "$FREQUENCY" &>/dev/null
}

# Function to convert text to Morse and play sounds
text_to_morse() {
    local text="$1" morse=""
    echo "Converting text to Morse:"

    # Convert each character to Morse and append to morse variable
    for (( i=0; i<${#text}; i++ )); do
        char=${text:i:1}
        morse+="${MORSE_CODE[${char^^}]+"${MORSE_CODE[${char^^}]} "}" # Correct handling to avoid adding "?" for spaces
    done

    echo "$morse"

    # Play Morse code
    for (( j=0; j<${#morse}; j++ )); do
        symbol=${morse:j:1}
        if [[ $symbol =~ [.-] ]]; then
            echo -n "$symbol"
            emit_sound "$symbol"
        elif [[ $symbol == " " ]]; then
            sleep 0.4 # Adjust for spacing between letters
        elif [[ $symbol == "/" ]]; then
            echo -n " / "
            sleep 0.7 # Adjust for spacing between words
        fi
    done
    echo
}


# Interactive mode to capture arrow keys for Morse code input
capture_arrow_keys() {
    echo "Interactive mode: Use up arrow for 'dah' and down arrow for 'dit'. Press 'q' to exit."
    local oldState key
    oldState=$(stty -g)
    stty raw -echo min 0 time 0
	while IFS= read -r -n1 key; do
        [[ $key == $'\x1b' ]] && {
            read -r -n2 -t 0.1 key2
            key+="$key2"
        }

        case $key in
            $'\x1b[A') # Setas para cima
                emit_sound "-"
                echo -n "dah "
                ;;
            $'\x1b[B') # Setas para baixo
                emit_sound "."
                echo -n "dit "
                ;;
            q) # Sair
                break
                ;;
            *)
                # Ignore other inputs
                ;;
        esac
    done
    stty "$oldState" # Restore terminal settings
    echo "Exiting interactive mode."
}

# Main loop with instructions
clear
echo "Instructions:"
echo "- Type 't' to convert text to Morse and play it."
echo "- Type 'i' to enter interactive mode."
echo "- Type 'f' to adjust the sound frequency."
echo "- Type 'q' to quit."

while :; do
    read -rp "Choose an option: " input

    case $input in
        t)
            echo "Enter a phrase to convert to Morse code and play:"
            read -r text
            text_to_morse "$text"
            ;;
        i)
            capture_arrow_keys
            ;;
        f)
            echo "Enter new sound frequency (in Hz):"
            read -r freq
            if [[ $freq =~ ^[0-9]+$ ]]; then
                FREQUENCY=$freq
                echo "Frequency set to $FREQUENCY Hz."
            else
                echo "Invalid input. Frequency unchanged."
            fi
            ;;
        q)
            echo "Program terminated."
            break
            ;;
        *)
            echo "Invalid option. Please choose a valid option."
            ;;
    esac
done
