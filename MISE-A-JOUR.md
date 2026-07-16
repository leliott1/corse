# Mettre à jour le site

1. Remplacer le contenu de `index.html` par la nouvelle version de la carte (garder impérativement le nom `index.html`).
2. `git add index.html && git commit -m "Mise à jour de la carte"`
3. `git push origin main` (branche de travail) puis `git push origin main:gh-pages` (la branche que GitHub Pages publie).
4. Attendre 1 à 2 minutes le temps du déploiement automatique.
5. Recharger https://leliott1.github.io/corse/ (forcer le cache si besoin : Ctrl+Maj+R).
