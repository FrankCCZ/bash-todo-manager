#!/bin/bash

# Pomocné funkce pro TODO aplikaci

# Definice barev
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
DGREEN='\033[0;32m'
NC='\033[0m'

# Vytvoření základní struktury složek a souborů
initialize_app() {
    mkdir -p lib data
    
    # Vytvoření tasks.db pokud neexistuje
    if [[ ! -f "data/tasks.db" ]]; then
        touch "data/tasks.db"
    fi
}

# Generování unikátního ID
generate_id() {
    local last_id=$(cut -d'|' -f1 "data/tasks.db" 2>/dev/null | sort -n | tail -n 1)
    echo $((${last_id:-0} + 1))
}

# Validace názvu úkolu
validate_task_name() {
    local name="$1"
    local max_length=255
    
    # Kontrola neprázdnosti
    [[ "$name" =~ [^[:space:]] ]] || return 1
    
    # Kontrola délky
    [[ ${#name} -le $max_length ]] || return 1
    
    return 0
}

# Validace formátu data nebo počtu dní
validate_deadline() {
    local input="$1"
    [[ -z "$input" ]] && return 0  # prázdný je OK
    [[ "$input" =~ ^[0-9]+$ ]] && return 0  # číslo je OK
    [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && date -d "$input" >/dev/null 2>&1
}

# Převod deadline vstupu na datum
process_deadline() {
    [[ -z "$1" ]] && return 0
    
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        date -d "+$1 days" +%Y-%m-%d
    else
        echo "$1"
    fi
}

# Kontrola, zda deadline není v minulosti
is_deadline_valid() {
    local deadline="$1"
    local today=$(date +%Y-%m-%d)
    
    if [[ -z "$deadline" ]]; then
        return 0
    fi
    
    if [[ "$deadline" < "$today" ]]; then
        return 1
    fi
    
    return 0
}

# Porovnání data s dneškem
is_overdue() {
    [[ -n "$1" ]] && [[ "$1" < "$(date +%Y-%m-%d)" ]]
}

# Zobrazování úkolů
display_tasks() {
    local filter_type="$1"    # "status", "search", nebo "all"
    local filter_value="$2"   # hodnota filtru
    local header_prefix="$3"  # prefix pro hlavičku (např. "Výsledky vyhledávání pro:")
    
    # Pokud neexistuje soubor, zobrazíme prázdnou tabulku
    if [[ ! -f "data/tasks.db" ]]; then
        if [[ -n "$header_prefix" ]]; then
            echo "$header_prefix '$filter_value'"
        fi
        echo "ID | Vytvořeno  | Deadline   | Status | Název"
        echo "---|------------|------------|--------|-------"
        return 0
    fi
    
    # Zobrazíme hlavičku
    if [[ -n "$header_prefix" ]]; then
        echo "$header_prefix '$filter_value'"
    fi
    echo "ID | Vytvořeno  | Deadline   | Status | Název"
    echo "---|------------|------------|--------|-------"
    
    while IFS='|' read -r id created deadline status name; do
        # Aplikace filtru podle typu
        case "$filter_type" in
            "status")
                case "$filter_value" in
                    "pending")
                        [[ "$status" != "pending" ]] && continue
                        ;;
                    "completed")
                        [[ "$status" != "completed" ]] && continue
                        ;;
                    "overdue")
                        [[ "$status" != "pending" ]] && continue
                        if ! is_overdue "$deadline"; then
                            continue
                        fi
                        ;;
                    "all")
                        # Nezfiltrujeme nic
                        ;;
                esac
                ;;
            "search")
                [[ "$name" != *"$filter_value"* ]] && continue
                ;;
            "all")
                # Nezfiltrujeme nic
                ;;
        esac
        
        # Formátování výstupu
        local deadline_display="${deadline:-    N/A   }"
        local today=$(date +%Y-%m-%d)

        if [[ "$status" == "completed" ]]; then
            echo -e "${DGREEN}$id | $created | $deadline_display | $status | $name${NC}"
        elif [[ "$status" == "pending" ]] && is_overdue "$deadline"; then
            echo -e "${RED}$id | $created | $deadline_display | $status | $name${NC}"
        elif [[ "$status" == "pending" ]] && [[ -n "$deadline" ]] && [[ "$deadline" < "$(date -d '+3 days' +%Y-%m-%d)" ]]; then
            echo -e "${YELLOW}$id | $created | $deadline_display | $status | $name${NC}"
        else
    echo "$id | $created | $deadline_display | $status | $name"
fi
       
    done < "data/tasks.db" 2>/dev/null
}


# Escape speciální znaky pro CSV
escape_csv() {
    local text="${1//\\/\\\\}"  # vypustit zpětná lomítka
    text="${text//|/\\|}"       # vypustit pipu 
    text="${text//$'\n'/ }"     # nahradit nové řádky mezerami
    echo "$text"
}

# Aktuální datum 
get_date() {
    date +"%Y-%m-%d"
}

# Kontrola existence úkolu podle ID
task_exists() {
    [[ -f "data/tasks.db" ]] && grep -q "^$1|" "data/tasks.db"
}

# Získání úkolu podle ID
get_task_by_id() {
    local id="$1"
    if [[ -f "data/tasks.db" ]]; then
        grep "^$id|" "data/tasks.db"
    fi
}