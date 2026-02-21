# License Header Framework (LHF) – Cadre déontologique pour créations honnêtes

Auteur : Thibaut LOMBARD
Version : 1.0.1
Repo : https://github.com/Lombard-Web-Services/deontology/

## Manifeste

Nous vivons aujourd’hui dans un monde où l’intelligence artificielle s’impose progressivement dans tous les secteurs. Cette expansion rend chaque jour plus difficile l’identification des véritables acteurs qui conçoivent, réalisent et diffusent les projets ou les œuvres.

Il est naturel de refuser que nos compétences, notre savoir-faire ou nos valeurs fondamentales soient remplacés ou dévoyés par des systèmes ou des individus moins compétents. Nous faisons face à une perte de repères : il devient de plus en plus ardu de savoir qui fait quoi et dans quelles intentions.

Mon constat personnel est clair : il devient de plus en plus difficile de distinguer une personne honnête d’un imposteur. Il est donc urgent de renouer avec l’honnêteté intellectuelle.

C’est dans cet esprit que j’ai développé LHF — une application Bash capable de générer des fichiers .deont et d’ajouter automatiquement les licences logicielles appropriées à chaque projet.

Cette approche vise à garantir la transparence et la traçabilité des créations, en consignant de manière fiable et vérifiable :
Qui • Quoi • Quand • Où • Pourquoi • Comment • À quelle heure précise • Avec quels outils • Avec qui • Sous quelle licence

Ce projet établit un cadre de travail déontologique clair et contrôlable, afin de restaurer la confiance, la responsabilité et la transparence au cœur des processus de création et de décision technologiques.

J’espère que cette initiative résonnera jusqu’aux plus hautes sphères, rappelant que l’éthique et la rigueur doivent toujours précéder la performance et la facilité.

## Fonctionnalités

• Création interactive ou rapide d’un fichier .deont (JSON)
• Support de toutes les licences (MIT, GPL, Apache, CC, etc.)
• Ajout automatique d’en-têtes de licence adaptés au langage (Python, JS, C, HTML, etc.)
• Mode récursif ou dossier unique
• Génération de rapport LaTeX + PDF professionnel
• Mode avancé : déclaration d’usage d’IA + rôle du créateur + notes manager
• Détection automatique des fichiers déjà licenciés
• Couleurs terminal, messages clairs, gestion d’erreurs robuste

## Points forts du code

• 100 % Bash portable + jq uniquement
• set -o pipefail + échappement sécurisé JSON/LaTeX
• Support de plus de 20 langages de commentaires
• Trap de nettoyage automatique des fichiers temporaires
• Code modulaire et facilement extensible

## Utilisation

# Création interactive complète
./lhf.sh create

# Création interactive avec champs avancés (IA, rôle, notes)
./lhf.sh create --advanced

# Création rapide en une ligne
./lhf.sh create -a "Thibaut LOMBARD" -l "MIT" -t "@LICENSE.txt" -y 2026

# Appliquer les headers
./lhf.sh apply -e js -r
./lhf.sh apply -e py --dir ./src

# Générer le PDF
./lhf.sh report --pdf-only

## Licence
MIT License © 2026 Thibaut LOMBARD
