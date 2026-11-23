#!/usr/bin/env bash
# Automatiza el flujo de ramas de la Práctica 3 (CSS + Git/GitHub)
# Uso: bash git-flujo.sh <comando> [argumentos]
# Funciona en Git Bash (Windows), Linux y macOS.
# Requiere: git. Opcional: GitHub CLI (gh) para crear/fusionar Pull Requests.

set -e

RAMAS_BASE=("desarrollo" "despliegue" "funcionalidad-inicio" "funcionalidad-servicios")

ayuda() {
cat <<'EOF'
COMANDOS

  init <URL_REPO>              Commit inicial, crea las 4 ramas y las sube a GitHub
  feature <rama> "<mensaje>"   Cambia a la rama, hace add + commit + push
  reto                         Crea la rama funcionalidad-reto (desde desarrollo) y la sube
  pr <rama>                    Crea un Pull Request <rama> -> desarrollo (necesita gh)
  merge <rama>                 Fusiona el Pull Request de <rama> (necesita gh)
  publicar                     desarrollo -> despliegue -> main (y los sube)
  verificar                    Muestra ramas, historial y Pull Requests

FLUJO RECOMENDADO

  bash git-flujo.sh init https://github.com/USUARIO/practica-css-nombre-apellido.git
  bash git-flujo.sh feature funcionalidad-inicio "Implementación de encabezado y navegación"
  bash git-flujo.sh feature funcionalidad-servicios "Implementación de servicios y galería"
  bash git-flujo.sh pr funcionalidad-inicio
  bash git-flujo.sh pr funcionalidad-servicios
  bash git-flujo.sh merge funcionalidad-inicio
  bash git-flujo.sh merge funcionalidad-servicios
  bash git-flujo.sh reto
  bash git-flujo.sh feature funcionalidad-reto "Implementación de la nueva sección (reto)"
  bash git-flujo.sh pr funcionalidad-reto
  bash git-flujo.sh merge funcionalidad-reto
  bash git-flujo.sh publicar
  bash git-flujo.sh verificar
EOF
}

tiene_gh() { command -v gh >/dev/null 2>&1; }

existe_rama() { git show-ref --verify --quiet "refs/heads/$1"; }

cmd_init() {
  URL="$1"
  [ -z "$URL" ] && { echo "Falta la URL del repositorio."; exit 1; }

  [ -d .git ] || git init
  git add .
  git commit -m "Creación de la estructura inicial del proyecto" || echo "(nada nuevo para commitear)"
  git branch -M main

  for r in "${RAMAS_BASE[@]}"; do
    existe_rama "$r" || git branch "$r"
  done

  if git remote | grep -q '^origin$'; then
    git remote set-url origin "$URL"
  else
    git remote add origin "$URL"
  fi

  git push -u origin main
  for r in "${RAMAS_BASE[@]}"; do
    git push -u origin "$r"
  done
  git switch main
  echo "✔ Repositorio inicializado y ramas subidas."
}

cmd_feature() {
  RAMA="$1"; MSG="$2"
  [ -z "$RAMA" ] || [ -z "$MSG" ] && { echo 'Uso: feature <rama> "<mensaje>"'; exit 1; }
  git switch "$RAMA"
  git add .
  git commit -m "$MSG" || echo "(no hay cambios nuevos)"
  git push -u origin "$RAMA"
  echo "✔ Cambios subidos a $RAMA."
}

cmd_reto() {
  git fetch origin
  git switch desarrollo
  git pull origin desarrollo || true
  if existe_rama funcionalidad-reto; then
    git switch funcionalidad-reto
  else
    git switch -c funcionalidad-reto
  fi
  git push -u origin funcionalidad-reto
  echo "✔ Rama funcionalidad-reto lista. Ahora edita index.html y estilos.css."
}

cmd_pr() {
  RAMA="$1"
  [ -z "$RAMA" ] && { echo "Uso: pr <rama>"; exit 1; }
  if tiene_gh; then
    gh pr create --base desarrollo --head "$RAMA" \
      --title "Integrar $RAMA en desarrollo" \
      --body "Pull Request de la rama $RAMA hacia desarrollo."
  else
    URL=$(git remote get-url origin | sed 's/\.git$//')
    echo "No tienes 'gh' instalado. Crea el Pull Request manualmente:"
    echo "  $URL/compare/desarrollo...$RAMA"
    echo "  (base: desarrollo  <-  compare: $RAMA)"
  fi
}

cmd_merge() {
  RAMA="$1"
  [ -z "$RAMA" ] && { echo "Uso: merge <rama>"; exit 1; }
  if tiene_gh; then
    gh pr merge "$RAMA" --merge
  else
    echo "Sin 'gh': entra al Pull Request en GitHub y pulsa 'Merge pull request'."
  fi
  git fetch origin
  git switch desarrollo
  git pull origin desarrollo
}

cmd_publicar() {
  git fetch origin
  git switch desarrollo
  git pull origin desarrollo

  git switch despliegue
  git merge desarrollo -m "Integración de desarrollo en despliegue"
  git push origin despliegue

  git switch main
  git merge despliegue -m "Integración de despliegue en main"
  git push origin main
  echo "✔ desarrollo -> despliegue -> main completado."
}

cmd_verificar() {
  echo "=== Ramas locales y remotas ==="
  git branch -a
  echo; echo "=== Historial (grafo) ==="
  git log --oneline --graph --all --decorate
  echo; echo "=== Pull Requests ==="
  if tiene_gh; then gh pr list --state all; else echo "(instala gh o revísalos en GitHub > Pull requests)"; fi
  echo; echo "=== Estado ==="
  git status -sb
}

case "$1" in
  init)      shift; cmd_init "$@" ;;
  feature)   shift; cmd_feature "$@" ;;
  reto)      cmd_reto ;;
  pr)        shift; cmd_pr "$@" ;;
  merge)     shift; cmd_merge "$@" ;;
  publicar)  cmd_publicar ;;
  verificar) cmd_verificar ;;
  *)         ayuda ;;
esac
