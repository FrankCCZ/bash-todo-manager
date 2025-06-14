# bash todo thing

todo app in bash because why not

## what it does

- add tasks
- list tasks  
- mark done
- delete stuff
- search
- shows stats
- has menu or use cli

## install

```bash
git clone this-repo
cd whatever-you-named-it
chmod +x todo.sh
./todo.sh
```

## usage

```bash
./todo.sh add "buy beer" 7
./todo.sh add "finish project" 2024-12-31
./todo.sh list
./todo.sh list P
./todo.sh complete 1
./todo.sh delete 2
./todo.sh search "beer"
./todo.sh stats
```

or just run `./todo.sh` for menu

## files

```
todo.sh           - main thing
lib/core.sh       - does stuff
lib/utils.sh      - helper stuff
data/tasks.db     - your tasks (auto created)
```

## filters

- A = all
- P = pending  
- C = completed
- O = overdue

## deadline formats

- `7` = 7 days from now
- `2024-12-31` = specific date

## requirements

bash, standard unix tools, working computer

## contributing

fork it, fix it, pr it

## license

MIT - do whatever

## bugs

file an issue or fix it yourself