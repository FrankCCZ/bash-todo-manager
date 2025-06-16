#!/bin/bash

# TODO Manager - Hlavní aplikace

# Import knihoven
source "lib/utils.sh"
source "lib/core.sh"

# Zobrazení nápovědy
show_help() {
    echo "TODO Manager - Správce úkolů"
    echo ""
    echo "Použití:"
    echo "  $0 add \"název\" [deadline]   - Přidat nový úkol"
    echo "  $0 list [filter]              - Zobrazit úkoly (A/P/C/O)"
    echo "  $0 complete ID                - Označit úkol jako dokončený"
    echo "  $0 delete ID                  - Smazat úkol"
    echo "  $0 search \"text\"            - Vyhledat úkoly"
    echo "  $0 stats                      - Zobrazit statistiky"
    echo "  $0 help                       - Zobrazit tuto nápovědu"
    echo ""
    echo "Filtry pro list:"
    echo "  A nebo all       - Všechny úkoly"
    echo "  P nebo pending   - Nevyřízené úkoly"
    echo "  C nebo completed - Dokončené úkoly"
    echo "  O nebo overdue   - Po termínu"
    echo ""
    echo "Deadline lze zadat jako:"
    echo "  - Počet dní: 7 (za týden)"
    echo "  - Konkrétní datum: 2024-06-20"
    echo ""
    echo "Spuštění bez argumentů otevře interaktivní menu."
    echo ""
    echo "Příklady:"
    echo "  $0 add \"Nakoupit pivo\" 7"
    echo "  $0 add \"Dokončit projekt\" 2024-06-20"
    echo "  $0 list P"
    echo "  $0 complete 1"
}

# Interaktivní menu
show_menu() {
    while true; do
        echo ""
        echo "=== TODO MANAGER ==="
        echo "1) Přidat úkol"
        echo "2) Zobrazit úkoly"
        echo "3) Označit jako dokončený"
        echo "4) Smazat úkol"
        echo "5) Vyhledat"
        echo "6) Statistiky"
        echo "0) Konec"
        echo ""
        read -p "Vyberte možnost [0-6]: " choice
        
        case $choice in
            1)
                read -p "Název úkolu: " task_name
                echo "Deadline můžete zadat jako:"
                echo "  - Počet dní (např. 7 = za týden)"
                echo "  - Konkrétní datum (YYYY-MM-DD)"
                echo "  - Enter pro přeskočení"
                read -p "Deadline: " deadline
                add_task "$task_name" "$deadline"
                ;;
            2)
                echo ""
                echo "Filtry: A (všechny), P (nevyřízené), C (dokončené), O (po termínu)"
                read -p "Filtr (enter pro všechny): " filter
                filter=${filter:-A}
                list_tasks "$filter"
                ;;
            3)
                list_tasks P
                echo ""
                read -p "ID úkolu k dokončení: " task_id
                complete_task "$task_id"
                ;;
            4)
                list_tasks A
                echo ""
                read -p "ID úkolu ke smazání: " task_id
                read -p "Opravdu smazat úkol s ID $task_id? (a/N): " confirm
                if [[ "$confirm" =~ ^[Aa]$ ]]; then
                    delete_task "$task_id"
                else
                    echo "Mazání zrušeno."
                fi
                ;;
            5)
                read -p "Hledaný text: " search_term
                search_tasks "$search_term"
                ;;
            6)
                show_stats
                ;;
            0)
                echo "Ukončuji TODO Manager. Na shledanou!"
                exit 0
                ;;
            *)
                echo -e "${RED}Neplatná volba. Zkuste znovu.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Stiskněte Enter pro pokračování..."
    done
}

# Hlavní funkce
main() {
    # Inicializace aplikace
    initialize_app
    
    # Zpracování argumentů
    case "${1:-}" in
        "add")
            if [[ -z "$2" ]]; then
                echo -e "${RED}Chyba: Název úkolu je povinný!${NC}"
                echo "Použití: $0 add \"název\" [deadline]"
                exit 1
            fi
            add_task "$2" "$3"
            ;;
        "list")
            list_tasks "$2"
            ;;
        "complete")
            if [[ -z "$2" ]]; then
                echo -e "${RED}Chyba: ID úkolu je povinné!${NC}"
                echo "Použití: $0 complete ID"
                exit 1
            fi
            complete_task "$2"
            ;;
        "delete")
            if [[ -z "$2" ]]; then
                echo -e "${RED}Chyba: ID úkolu je povinné!${NC}"
                echo "Použití: $0 delete ID"
                exit 1
            fi
            delete_task "$2"
            ;;
        "search")
            if [[ -z "$2" ]]; then
                echo -e "${RED}Chyba: Hledaný text je povinný!${NC}"
                echo "Použití: $0 search \"text\""
                exit 1
            fi
            search_tasks "$2"
            ;;
        "stats")
            show_stats
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        "")
            # Spuštění bez argumentů - interaktivní menu
            show_menu
            ;;
        *)
            echo -e "${RED}Neznámý příkaz: $1${NC}"
            echo "Použijte '$0 help' pro nápovědu."
            exit 1
            ;;
    esac
}

# Spuštění hlavní funkce
main "$@"