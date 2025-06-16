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
                    echo -e "${RED}Chyba: Deadline nemůže být v minulosti!${NC}"
                fi
            else
                echo -e "${RED}Chyba: Neplatný formát deadline!${NC}"
            fi
            
            # Zobrazit instrukce a zeptat se znovu
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
    
    display_tasks "status" "$filter"
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

# Vyhledávání
search_tasks() {
    local search_term="$1"
    
    if [[ -z "$search_term" ]]; then
        echo -e "${RED}Chyba: Hledaný výraz je povinný!${NC}"
        return 1
    fi
    
    display_tasks "search" "$search_term" "Výsledky vyhledávání pro:"
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