#!/usr/bin/env bash
# Repara el repositorio: deja main/desarrollo/despliegue con la ESTRUCTURA BASE
# (sin funcionalidades) y recrea las ramas de funcionalidad desde ahí.
# Conserva tus imágenes finales (las toma de la rama funcionalidad-reto si existe).
# Ejecutar DENTRO de la carpeta del proyecto: bash reparar.sh
set -e

[ -d .git ] || { echo "Ejecuta esto dentro de la carpeta del proyecto."; exit 1; }
[ -f _etapas/3-reto/index.html ] || { echo "No encuentro la carpeta _etapas."; exit 1; }

# 1. Respaldo de tus imágenes finales (están en la rama del reto)
if git show-ref --verify --quiet refs/heads/funcionalidad-reto; then
  git switch funcionalidad-reto
fi
rm -rf ../respaldo-imagenes
cp -r imagenes ../respaldo-imagenes
echo "Respaldo de imágenes en ../respaldo-imagenes"

# 2. Volver a main y restaurar tus imágenes
git switch -f main
cp -r ../respaldo-imagenes/. imagenes/

# 3. Generar la versión BASE (sin los bloques de inicio, servicios y reto)
quitar() {
  awk '/BEGIN:/{print; skip=1; next} /END:/{skip=0; print; next} skip!=1{print}' "$1" | grep -v 'reto-nav'
}
quitar _etapas/3-reto/index.html > index.html
quitar _etapas/3-reto/css/estilos.css > css/estilos.css

# 4. Commit de la base y subida a main
git add -A
git reset -q reparar.sh 2>/dev/null || true
git commit -m "Estructura base del proyecto (sin funcionalidades)"
git push origin main

# 5. Recrear las demás ramas desde main y subirlas
for r in desarrollo despliegue funcionalidad-inicio funcionalidad-servicios; do
  git branch -f "$r" main
  git push --force origin "$r"
done

# 6. Eliminar la rama del reto antigua (se vuelve a crear con: bash git-flujo.sh reto)
git branch -D funcionalidad-reto 2>/dev/null || true
git push origin --delete funcionalidad-reto 2>/dev/null || true

git switch main
echo "✔ Listo. Ahora repite: rama inicio, rama servicios y Pull Requests."
