# License Header Framework (LHF)

### Cadre d'éthique et de transparence des licences

**Auteur :** Thibaut LOMBARD  
**Dépôt :** [https://github.com/Lombard-Web-Services/deontology/](https://github.com/Lombard-Web-Services/deontology/)  
**Licence :** MIT © 2026 Thibaut LOMBARD

## Résumé

Le **License Header Framework (LHF)** est un utilitaire Bash de niveau professionnel
conçu pour garantir la clarté éthique, la transparence de l'auteur,
et la structuration des licences dans les projets logiciels.

À mesure que l'intelligence artificielle et les systèmes automatisés participent
de plus en plus à la production de contenus et de logiciels, il devient complexe
d'identifier la responsabilité et la paternité des œuvres.  
LHF établit un cadre vérifiable, structuré et auditable pour documenter intelligemment.

LHF promeut l'honnêteté intellectuelle, la traçabilité et la responsabilité professionnelle dans les environnements de développement modernes.

## Manifeste

Nous vivons une ère où l'intelligence artificielle s'impose progressivement dans tous les secteurs.  
Cette expansion rend de plus en plus difficile l'identification des véritables acteurs qui conçoivent, construisent et publient les projets ou les œuvres.

Il est légitime de refuser que nos compétences, notre expertise ou nos valeurs fondamentales soient remplacées ou déformées par des systèmes ou individus dépourvus de compétence ou d'intégrité.  
Nous faisons face à une perte de repères : il devient difficile de déterminer qui fait quoi — et avec quelle intention.

Mon constat personnel est clair : il devient de plus en plus ardu de distinguer un individu honnête d'un imposteur. Il est donc urgent de restaurer l'honnêteté intellectuelle.

C'est dans cet esprit que j'ai développé **LHF** — une application Bash capable de générer des fichiers `.deont` et d'ajouter automatiquement la licence logicielle appropriée à chaque projet.

Cette approche vise à garantir la transparence et la traçabilité en documentant, de manière fiable et vérifiable :

&gt; **Qui • Quoi • Quand • Où • Pourquoi • Comment • Heure précise • Avec quels outils • Avec qui • Sous quelle licence**

Ce projet établit un cadre déontologique clair et auditable, conçu pour restaurer la confiance, la responsabilité et la transparence au cœur de la création technologique et des processus décisionnels.

J'espère sincèrement que cette initiative résonnera jusqu'aux plus hauts niveaux, rappelant que l'éthique et la rigueur doivent toujours précéder la performance et la commodité.

## Fonctionnalités principales

- Création interactive ou rapide de fichiers `.deont` (format JSON)
- Support de toutes les licences majeures (MIT, GPL, Apache, BSD, Creative Commons, etc.)
- Insertion automatique d'en-têtes de licence adaptés au langage (Python, JavaScript, C, C++, HTML, Shell, et plus de 20 autres)
- Modes de traitement récursif ou par répertoire unique
- **Application de licence sur fichier unique** : ciblez un fichier spécifique plutôt qu'un répertoire entier
- **Support de fichier .deont externe** : utilisez un fichier de configuration situé dans un autre répertoire
- Génération de rapports professionnels en LaTeX avec export PDF optionnel
- Mode avancé incluant :
  - Déclaration d'utilisation d'IA  
  - Spécification du rôle du créateur  
  - Notes de conformité ou managériales
- Détection automatique des fichiers déjà licenciés
- Sortie colorée dans le terminal et gestion robuste des erreurs

## Architecture technique

- 100 % Bash portable (compatible POSIX)  
- Dépendance externe unique : `jq`  
- `set -o pipefail` activé pour la propagation stricte des erreurs  
- Échappement sécurisé JSON et LaTeX  
- Support de plus de 20 syntaxes de commentaires  
- Nettoyage automatique des fichiers temporaires via des gestionnaires *trap*  
- Code modulaire, maintenable et extensible

## Installation

``` bash
git clone https://github.com/Lombard-Web-Services/deontology.git 
cd deontology
chmod +x lhf.sh
```

Installer la dépendance :

``` bash
sudo apt install jq
```

## Utilisation

### Création interactive complète

``` bash
./lhf.sh create
```

### Mode interactif avancé

``` bash
./lhf.sh create --advanced
```

### Création rapide en une ligne

``` bash
./lhf.sh create -a "Thibaut LOMBARD" -l "MIT" -t "@LICENSE.txt" -y 2026
```

### Application des en-têtes de licence

Mode récursif :

``` bash
./lhf.sh apply -e js -r
```

Répertoire spécifique :

``` bash
./lhf.sh apply -e py --dir ./src
```

**Fichier unique avec .deont externe :**

Vous pouvez appliquer une licence à un fichier spécifique en utilisant un fichier `.deont` situé dans un autre répertoire. L'option `--dir` accepte soit un répertoire (mode récursif), soit un chemin de fichier unique.

``` bash
./lhf.sh apply -f /chemin/vers/.deont -e sh --dir ./monfichier.sh
```

Dans cet exemple :
- `-f /chemin/vers/.deont` : chemin vers le fichier de configuration externe
- `-e sh` : extension du fichier cible
- `--dir ./monfichier.sh` : chemin vers le fichier spécifique à licencier

**Autre exemple avec .deont externe :**

``` bash
./lhf.sh apply -f .deont -e js --dir ./dossier/
```

Cette commande applique la licence définie dans le fichier `.deont` du répertoire courant aux fichiers JavaScript du répertoire `./dossier/`.

### Génération de rapport professionnel (PDF seulement)

``` bash
./lhf.sh report --pdf-only
```

## Changelog

### Version 2.0.7

- **Amélioration** : Prise en charge améliorée des commentaires des en-têtes de licence
- **Correction** : Affichage corrigé pour les langages C, Python et CSS
- **Correction** : Affichage corrigé pour les langages HTML, CSS et JavaScript
- **Nouvelle fonctionnalité** : Application des licences sur des fichiers uniques (mode fichier cible)
- **Nouvelle fonctionnalité** : Lecture des fichiers à partir d'un fichier `.deont` externe

## Philosophie de gouvernance

LHF n'est pas seulement un script de licence.

C'est une **couche de gouvernance déontologique** dédiée à la création logicielle.  
Ses objectifs :

- Renforcer la responsabilité éthique dans les flux de développement  
- Clarifier les contributions humaines et celles de l'IA  
- Garantir l'auditabilité et la traçabilité sur le long terme  
- Élever les standards professionnels de la production numérique

La technologie doit rester responsable.  
L'automatisation ne doit jamais remplacer l'intégrité.

## Contribution

Les contributions sont les bienvenues, à condition qu'elles respectent les principes éthiques et de transparence du cadre.

## Licence

Distribué sous la licence MIT.  
© 2026 Thibaut LOMBARD
