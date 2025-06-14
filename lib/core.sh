#!/bin/bash

# Hlavní funkce pro TODO aplikaci

# Import utils funkcí
source "lib/utils.sh"

# Přidání nového úkolu
add_task() {
    local name="$1"
    local deadline_input="$2"
    
    # Validace názvu
    if ! validate_task_name "$name"; then
        echo "Chyba: Název úkolu nemůže být prázdný, může mít max. 255 znaků!"
        return 1
    fi
    
    local deadline=""
    
    # Zpracování deadline
    if [[ -n "$deadline_input" ]]; then
    while true; do
        if validate_deadline "$deadline_input"; then
            deadline=$(process_deadline "$deadline_input")
            if is_deadline_valid "$deadline"; then
                break
            else
                error_msg="Chyba: Deadline nemůže být v minulosti!"
            fi
        else
            error_msg="Chyba: Neplatný formát deadline!"
        fi
        
        # Zobrazit chybu a instrukce
        echo -e "${RED}$error_msg${NC}"
        echo "Zadejte deadline jako:"
        echo "  - Počet dní (např. 7 = za týden)"
        echo "  - Konkrétní datum (YYYY-MM-DD)"
        echo "  - Enter pokud není deadline"
        
        read -p "Deadline: " deadline_input
        if [[ -z "$deadline_input" ]]; then
            deadline=""
            break
        fi
    done
fi
    
    # Escape speciálních znaků
    name=$(escape_csv "$name")
    
    # Generování ID a datum vytvoření
    local id=$(generate_id)
    local created=$(get_date)
    
    # Uložení do databáze - formát: ID|vytvořeno|deadline|status|název
    echo "$id|$created|$deadline|pending|$name" >> "data/tasks.db"
    echo -e "${YELLOW}Úkol přidán s ID: $id${NC}"
    return 0
}

# Výpis úkolů
list_tasks() {
    local filter_input="${1:-A}"
    
    # Převod zkrácených filtrů na plné názvy
    local filter
    case "${filter_input^^}" in
        "A"|"ALL") filter="all" ;;
        "P"|"PENDING") filter="pending" ;;
        "C"|"COMPLETED") filter="completed" ;;
        "O"|"OVERDUE") filter="overdue" ;;
        *) filter="all" ;;
    esac
    
    if [[ ! -f "data/tasks.db" || ! -s "data/tasks.db" ]]; then
        echo -e "${YELLOW}Žádné úkoly nenalezeny.${NC}"
        return 0
    fi
    
    echo "ID | Vytvořeno  | Deadline   | Status | Název"
    echo "---|------------|------------|--------|-------"
    
    while IFS='|' read -r id created deadline status name; do
        # Aplikace filtru
        case "$filter" in
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
        esac
        
        # Formátování výstupu
        local deadline_display="${deadline:-    N/A   }"
        if [[ "$status" == "pending" ]] && is_overdue "$deadline"; then
            echo -e "${RED}$id | $created | $deadline_display | $status | $name${NC}"
        elif [[ "$status" == "completed" ]]; then
            echo -e "${DGREEN}$id | $created | $deadline_display | $status | $name${NC}"
        else
            echo "$id | $created | $deadline_display | $status | $name"
        fi
    done < "data/tasks.db"
}

# Označení úkolu jako dokončený
complete_task() {
    local id="$1"
    
    if [[ -z "$id" ]]; then
        echo -e "${RED}Chyba: ID úkolu je povinné!${NC}"
        return 1
    fi
    
    if ! task_exists "$id"; then
        echo -e "${RED}Chyba: Úkol s ID $id neexistuje!${NC}"
        return 1
    fi
    
    # Kontrola zda už není dokončen
    local current_status=$(get_task_by_id "$id" | cut -d'|' -f4)
    if [[ "$current_status" == "completed" ]]; then
        echo -e "${RED}Úkol s ID $id je již dokončen!${NC}"
        return 1
    fi
    
    local temp_file=$(mktemp)
    
    # Aktualizace statusu - formát: ID|created|deadline|status|name
    while IFS='|' read -r task_id created deadline status name; do
        if [[ "$task_id" == "$id" ]]; then
            echo "$task_id|$created|$deadline|completed|$name" >> "$temp_file"
        else
            echo "$task_id|$created|$deadline|$status|$name" >> "$temp_file"
        fi
    done < "data/tasks.db"
    
    mv "$temp_file" "data/tasks.db"
    echo -e "${YELLOW}Úkol s ID $id označen jako dokončený!${NC}"
    return 0
}

# Smazání úkolu
delete_task() {
    local id="$1"
    
    if [[ -z "$id" ]]; then
        echo -e "${RED}Chyba: ID úkolu je povinné!${NC}"
        return 1
    fi
    
    if ! task_exists "$id"; then
        echo -e "${RED}Chyba: Úkol s ID $id neexistuje!${NC}"
        return 1
    fi
    
    local temp_file=$(mktemp)
    grep -v "^$id|" "data/tasks.db" > "$temp_file"
    mv "$temp_file" "data/tasks.db"
    
    echo -e "${YELLOW}Úkol s ID $id byl smazán!${NC}"
    return 0
}



# Vyhledávání v úkolech
search_tasks() {
    local search_term="$1"
    
    if [[ -z "$search_term" ]]; then
        echo -e "${RED}Chyba: Hledaný výraz je povinný!${NC}"
        return 1
    fi
    
    if [[ ! -f "data/tasks.db" || ! -s "data/tasks.db" ]]; then
        echo -e "${YELLOW}Žádné úkoly nenalezeny.${NC}"
        return 0
    fi
    
    echo "Výsledky vyhledávání pro: '$search_term'"
    echo "ID | Vytvořeno  | Deadline   | Status | Název"
    echo "---|------------|------------|--------|-------"
    
    local found=0
    while IFS='|' read -r id created deadline status name; do
        if [[ "$name" == *"$search_term"* ]]; then
            local deadline_display="${deadline:-    N/A   }"
            echo "$id | $created | $deadline_display | $status | $name"
            found=1
        fi
    done < "data/tasks.db"
    
    if [[ $found -eq 0 ]]; then
        echo -e "${YELLOW}Žádné úkoly nebyly nalezeny.${NC}"
    fi
}

# Statistiky úkolů
show_stats() {
    if [[ ! -f "data/tasks.db" || ! -s "data/tasks.db" ]]; then
        echo -e "${YELLOW}Žádné úkoly nenalezeny.${NC}"
        return 0
    fi
    
    local total=0
    local pending=0
    local completed=0
    local overdue=0
    
    while IFS='|' read -r id created deadline status name; do
        ((total++))
        if [[ "$status" == "pending" ]]; then
            ((pending++))
            if is_overdue "$deadline"; then
                ((overdue++))
            fi
        elif [[ "$status" == "completed" ]]; then
            ((completed++))
        fi
    done < "data/tasks.db"
    
    echo "=== STATISTIKY ÚKOLŮ ==="
    echo "Celkem úkolů: $total"
    echo "Nevyřízené: $pending"
    echo "Dokončené: $completed"
    echo -e ${RED}"Po termínu: $overdue${NC}"
    
    if [[ $total -gt 0 ]]; then
        local completion_rate=$((completed * 100 / total))
        echo -e ${YELLOW}"Míra dokončení: ${completion_rate}%${NC}"
    fi
}