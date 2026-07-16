# Mettre à jour le site

1. Le plus simple, sans rien installer : sur https://github.com/leliott1/corse, ouvrir `index.html`, cliquer sur le crayon ✏️, coller la nouvelle version, puis « Commit changes ».
2. Ou en ligne de commande : remplacer `index.html` (garder ce nom), puis `git add index.html && git commit -m "maj" && git push origin main`.
3. Dans les deux cas, la publication est automatique (une action GitHub copie `main` vers la branche publiée).
4. Attendre 1 à 2 minutes.
5. Recharger https://leliott1.github.io/corse/ (forcer le cache si besoin : Ctrl+Maj+R).
