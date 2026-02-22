#!/bin/bash

# ======================================================================== #
#  INFORMATIONS DE LICENCE                                                 #
# ======================================================================== #
#  Auteur(s) : Thibaut LOMBARD (LombardWeb)                                #
#  Type de Licence : MIT                                                   #
#  Copyright : © 2026 Thibaut LOMBARD (LombardWeb)                         #
#  Date d'Émission : 2026-02-21                                            #
#  Lien de la Licence : https://opensource.org/license/mit                  #
#  Technique IA : Prompting                                                #
#  Rôle du Créateur : Chef de Projet et Architecte Logiciel, Ingénieur     #
#  Machine Learning                                                        #
#  ID Système : a15fbc9745ea0cfa                                           #
#  Fichiers Cibles : sh                                                    #
# ======================================================================== #
#                                                                          #
# L'autorisation est accordée, gracieusement, à toute personne obtenant    #
# une copie de ce logiciel et des fichiers de documentation associés (le   #
# « Logiciel »), de traiter le Logiciel sans restriction, y compris sans    #
# limitation les droits d'utiliser, copier, modifier, fusionner, publier,  #
# distribuer, sous-licencier et/ou vendre des copies du Logiciel, et de    #
# permettre aux personnes à qui le Logiciel est fourni de le faire, sous   #
# réserve des conditions suivantes :                                       #
#                                                                          #
# L'avis de copyright ci-dessus et cet avis d'autorisation doivent être    #
# inclus dans toutes les copies ou parties substantielles du Logiciel.     #
#                                                                          #
# LE LOGICIEL EST FOURNI « EN L'ÉTAT », SANS GARANTIE D'AUCUNE SORTE,      #
# EXPLICITE OU IMPLICITE, Y COMPRIS MAIS SANS LIMITATION LES GARANTIES DE  #
# QUALITÉ MARCHANDE, D'ADÉQUATION À UN USAGE PARTICULIER ET D'ABSENCE DE   #
# CONTREFAÇON. EN AUCUN CAS LES AUTEURS OU TITULAIRES DU COPYRIGHT NE      #
# POURRONT ÊTRE TENUS RESPONSABLES DE TOUTE RÉCLAMATION, DOMMAGES OU       #
# AUTRES RESPONSABILITÉS, QUE CE SOIT DANS UNE ACTION CONTRACTUELLE,       #
# DÉLICTUELLE OU AUTRE, DÉCOULANT DE, HORS OU EN RELATION AVEC LE          #
# LOGICIEL OU L'UTILISATION OU AUTRES TRANSACTIONS DANS LE LOGICIEL.       #
# ======================================================================== #

#===============================================================================
# CADRE D'EN-TÊTE DE LICENCE (LHF)
# Version : 2.0.7 - Blocs de commentaires rectangulaires fixes avec largeur cohérente
#===============================================================================

set -o pipefail

readonly SCRIPT_NAME="lhf"
readonly VERSION="2.0.7"
readonly DEONT_VERSION="2.0"
readonly DEFAULT_CONFIG_DIR="$HOME/.config/lhf"
readonly TEMPLATES_DIR="$DEFAULT_CONFIG_DIR/templates"
readonly TEMP_DIR="/tmp/lhf_$$"

# Largeur fixe pour tous les blocs de commentaires
readonly BLOCK_WIDTH=76

# Codes couleur
declare -A COLORS=(
  [reset]='\033[0m'
  [bold]='\033[1m'
  [red]='\033[0;31m'
  [green]='\033[0;32m'
  [yellow]='\033[0;33m'
  [blue]='\033[0;34m'
  [magenta]='\033[0;35m'
  [cyan]='\033[0;36m'
)

# Styles de commentaires
declare -A COMMENT_STYLES=(
  ['sh']='hash' ['bash']='hash' ['zsh']='hash' ['py']='hash' ['rb']='hash'
  ['pl']='hash' ['yaml']='hash' ['yml']='hash' ['conf']='hash'
  ['dockerfile']='hash' ['makefile']='hash'
  ['c']='c_style' ['cpp']='c_style' ['h']='c_style' ['hpp']='c_style'
  ['java']='c_style' ['js']='js_style' ['ts']='js_style' ['css']='c_style'
  ['scss']='c_style' ['go']='c_style' ['rs']='c_style' ['swift']='c_style'
  ['kt']='c_style'
  ['html']='html_style' ['xml']='html_style' ['svg']='html_style' ['md']='html_style'
  ['lua']='lua_style' ['sql']='sql_style' ['vim']='vim_style'
)

#-------------------------------------------------------------------------------
# FONCTIONS UTILITAIRES
#-------------------------------------------------------------------------------

print_banner() {
  echo -e "${COLORS[cyan]}"
  cat << 'EOF'

╔═══════════════════════════════════════════════════════════════╗
║           📜  CADRE D'EN-TÊTE DE LICENCE (LHF)  📜            ║
║         Empreinte Système & Génération PDF Améliorée          ║
╚═══════════════════════════════════════════════════════════════╝

EOF
  echo -e "${COLORS[reset]}"
}

print_error()   { echo -e "${COLORS[red]}[ERREUR]${COLORS[reset]} $1" >&2; }
print_success() { echo -e "${COLORS[green]}[SUCCÈS]${COLORS[reset]} $1" >&2; }
print_info()    { echo -e "${COLORS[blue]}[INFO]${COLORS[reset]} $1" >&2; }
print_warning() { echo -e "${COLORS[yellow]}[ATTENTION]${COLORS[reset]} $1" >&2; }
print_prompt()  { echo -e "${COLORS[magenta]}➜${COLORS[reset]} ${COLORS[bold]}$1${COLORS[reset]}" >&2; }

check_dependencies() {
  print_info "Vérification des dépendances..."
  if ! command -v jq &> /dev/null; then
    print_error "Dépendance requise manquante : jq"
    print_info "Installer avec : sudo apt-get install jq"
    exit 1
  fi
  print_success "Toutes les dépendances sont satisfaites"
}

create_temp_dir() {
  mkdir -p "$TEMP_DIR"
  if [[ ! -d "$TEMP_DIR" ]]; then
    print_error "Échec de la création du répertoire temporaire"
    exit 1
  fi
  trap 'rm -rf "$TEMP_DIR"' EXIT
}

#-------------------------------------------------------------------------------
# EMPREINTE SYSTÈME
#-------------------------------------------------------------------------------
generate_system_fingerprint() {
  print_info "Génération de l'empreinte système unique..." >&2

  local data=""
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if [[ -f /etc/machine-id ]]; then
    data+="MACHINE_ID:$(cat /etc/machine-id 2>/dev/null)\n"
  fi
  if [[ -f /var/lib/dbus/machine-id ]]; then
    data+="DBUS_ID:$(cat /var/lib/dbus/machine-id 2>/dev/null)\n"
  fi

  for file in /sys/class/dmi/id/*; do
    if [[ -r "$file" && -f "$file" ]]; then
      local basename_file
      basename_file=$(basename "$file")
      local content
      content=$(cat "$file" 2>/dev/null | tr -d '\n' | head -c 200)
      content=$(echo "$content" | sed 's/\\/\\\\/g; s/"/\\"/g')
      data+="${basename_file}:${content}\n"
    fi
  done

  for mac in /sys/class/net/*/address; do
    if [[ -r "$mac" ]]; then
      local mac_addr
      mac_addr=$(cat "$mac" 2>/dev/null)
      data+="MAC:${mac_addr}\n"
    fi
  done

  while read -r uuid; do
    if [[ -n "$uuid" ]]; then
      data+="DISK_UUID:${uuid}\n"
    fi
  done < <(lsblk -o UUID -n 2>/dev/null | sort -u)

  local cpu_model
  cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
  if [[ -n "$cpu_model" ]]; then
    cpu_model=$(echo "$cpu_model" | sed 's/\\/\\\\/g; s/"/\\"/g')
    data+="CPU_MODEL:${cpu_model}\n"
  fi

  local cpu_cores
  cpu_cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "0")
  data+="CPU_CORES:${cpu_cores}\n"

  local fingerprint_hash
  fingerprint_hash=$(echo -e "$data" | sha256sum | awk '{print $1}')
  fingerprint_hash="${fingerprint_hash:0:16}"

  local hostname_val
  hostname_val=$(hostname 2>/dev/null || echo "inconnu")

  jq -n \
    --arg hash "$fingerprint_hash" \
    --arg timestamp "$timestamp" \
    --arg hostname "$hostname_val" \
    --arg cpu_model "$cpu_model" \
    --arg cpu_cores "$cpu_cores" \
    '{
      fingerprint_hash: $hash,
      generated_at: $timestamp,
      system_info: {
        hostname: $hostname,
        cpu_model: $cpu_model,
        cpu_cores: $cpu_cores
      }
    }'
}

#-------------------------------------------------------------------------------
# FONCTIONS PRINCIPALES
#-------------------------------------------------------------------------------
get_comment_style() {
  local extension="$1"
  echo "${COMMENT_STYLES[$extension]:-hash}"
}

# Enveloppe le texte aux limites de mots avec largeur exacte
wrap_text_exact() {
  local text="$1"
  local width="$2"
  echo "$text" | fold -s -w "$width" | while IFS= read -r line; do
    # Supprime les espaces de fin
    line="${line%"${line##*[![:space:]]}"}"
    echo "$line"
  done
}

# Remplit ou tronque la ligne à la largeur exacte
format_line() {
  local line="$1"
  local width="$2"
  local len=${#line}
  
  if [[ $len -gt $width ]]; then
    # Tronque avec points de suspension si trop long
    echo "${line:0:$((width-3))}..."
  elif [[ $len -lt $width ]]; then
    # Remplit avec des espaces
    printf "%s%*s" "$line" $((width - len)) ""
  else
    echo "$line"
  fi
}

format_comment_block() {
  local style="$1"
  local content="$2"
  
  case "$style" in
    'hash')
      # Style Shell/Python : # commentaire
      local inner_width=$((BLOCK_WIDTH - 4))  # "# " et " #"
      
      # Traite tout le contenu
      local output_lines=()
      while IFS= read -r line || [[ -n "$line" ]]; do
        local trimmed="${line%"${line##*[![:space:]]}"}"
        
        if [[ "$trimmed" =~ ^[=\-]{10,}$ ]]; then
          local sep=$(printf '=%.0s' $(seq 1 $inner_width))
          output_lines+=("# $sep #")
        elif [[ -z "$trimmed" ]]; then
          output_lines+=("# $(printf '%*s' $inner_width '') #")
        else
          while IFS= read -r wrapped; do
            local formatted=$(format_line "$wrapped" "$inner_width")
            output_lines+=("# $formatted #")
          done < <(wrap_text_exact "$line" "$inner_width")
        fi
      done <<< "$content"
      
      # Ajoute le séparateur final si nécessaire
      local last_line="${output_lines[-1]}"
      local check_sep="${last_line//#/}"
      check_sep="${check_sep// /}"
      if [[ ! "$check_sep" =~ ^={10,}$ ]]; then
        local final_sep=$(printf '=%.0s' $(seq 1 $inner_width))
        output_lines+=("# $final_sep #")
      fi
      
      printf '%s\n' "${output_lines[@]}"
      ;;
      
    'js_style')
      # JavaScript : /* ligne */ - chaque ligne séparée
      local inner_width=$((BLOCK_WIDTH - 6))  # "/* " et " */"
      
      local output_lines=()
      while IFS= read -r line || [[ -n "$line" ]]; do
        local trimmed="${line%"${line##*[![:space:]]}"}"
        
        if [[ "$trimmed" =~ ^[=\-]{10,}$ ]]; then
          local sep=$(printf '=%.0s' $(seq 1 $inner_width))
          output_lines+=("/* $sep */")
        elif [[ -z "$trimmed" ]]; then
          output_lines+=("/* $(printf '%*s' $inner_width '') */")
        else
          while IFS= read -r wrapped; do
            local formatted=$(format_line "$wrapped" "$inner_width")
            output_lines+=("/* $formatted */")
          done < <(wrap_text_exact "$line" "$inner_width")
        fi
      done <<< "$content"
      
      # Ajoute le séparateur final
      local last_line="${output_lines[-1]}"
      local check_sep="${last_line//\/*/}"
      check_sep="${check_sep// /}"
      if [[ ! "$check_sep" =~ ^={10,}$ ]]; then
        local final_sep=$(printf '=%.0s' $(seq 1 $inner_width))
        output_lines+=("/* $final_sep */")
      fi
      
      printf '%s\n' "${output_lines[@]}"
      ;;
      
	'c_style')
	  # CSS/C/Java : séparé /* */ par ligne (comme le style JS mais avec bordures pleine largeur)
	  local inner_width=$((BLOCK_WIDTH - 6))  # "/* " et " */"
	  
	  local output_lines=()
	  
	  while IFS= read -r line || [[ -n "$line" ]]; do
		local trimmed="${line%"${line##*[![:space:]]}"}"
		
		if [[ "$trimmed" =~ ^[=\-]{10,}$ ]]; then
		  local sep=$(printf '=%.0s' $(seq 1 $inner_width))
		  output_lines+=("/* $sep */")
		elif [[ -z "$trimmed" ]]; then
		  output_lines+=("/* $(printf '%*s' $inner_width '') */")
		else
		  while IFS= read -r wrapped; do
			local formatted=$(format_line "$wrapped" "$inner_width")
			output_lines+=("/* $formatted */")
		  done < <(wrap_text_exact "$line" "$inner_width")
		fi
	  done <<< "$content"
	  
	  # Ajoute le séparateur final
	  local last_line="${output_lines[-1]}"
	  local check_sep="${last_line//\/*/}"
	  check_sep="${check_sep// /}"
	  if [[ ! "$check_sep" =~ ^={10,}$ ]]; then
		local final_sep=$(printf '=%.0s' $(seq 1 $inner_width))
		output_lines+=("/* $final_sep */")
	  fi
	  
	  printf '%s\n' "${output_lines[@]}"
	  ;;
      
    'html_style')
      # HTML : <!-- contenu -->
      local inner_width=$((BLOCK_WIDTH - 6))  # "  " et "  "
      
      local output_lines=()
      output_lines+=("<!--")
      
      while IFS= read -r line || [[ -n "$line" ]]; do
        local trimmed="${line%"${line##*[![:space:]]}"}"
        
        if [[ "$trimmed" =~ ^[=\-]{10,}$ ]]; then
          local sep=$(printf '=%.0s' $(seq 1 $inner_width))
          output_lines+=("  $sep  ")
        elif [[ -z "$trimmed" ]]; then
          output_lines+=("  $(printf '%*s' $inner_width '')  ")
        else
          while IFS= read -r wrapped; do
            local formatted=$(format_line "$wrapped" "$inner_width")
            output_lines+=("  $formatted  ")
          done < <(wrap_text_exact "$line" "$inner_width")
        fi
      done <<< "$content"
      
      # Ajoute le séparateur final si nécessaire
      local last_line="${output_lines[-1]}"
      local check_sep="${last_line// /}"
      if [[ ! "$check_sep" =~ ^={10,}$ ]] && [[ "$last_line" != "<!--" ]]; then
        local final_sep=$(printf '=%.0s' $(seq 1 $inner_width))
        output_lines+=("  $final_sep  ")
      fi
      
      output_lines+=("-->")
      
      printf '%s\n' "${output_lines[@]}"
      ;;
      
    'lua_style')
      # Lua : --[[ contenu ]]
      local inner_width=$((BLOCK_WIDTH - 6))  # " " et " " à l'intérieur
      
      local output_lines=()
      output_lines+=("--[[")
      
      while IFS= read -r line || [[ -n "$line" ]]; do
        local trimmed="${line%"${line##*[![:space:]]}"}"
        
        if [[ "$trimmed" =~ ^[=\-]{10,}$ ]]; then
          local sep=$(printf '=%.0s' $(seq 1 $inner_width))
          output_lines+=(" $sep ")
        elif [[ -z "$trimmed" ]]; then
          output_lines+=(" $(printf '%*s' $inner_width '') ")
        else
          while IFS= read -r wrapped; do
            local formatted=$(format_line "$wrapped" "$inner_width")
            output_lines+=(" $formatted ")
          done < <(wrap_text_exact "$line" "$inner_width")
        fi
      done <<< "$content"
      
      # Ajoute le séparateur final si nécessaire
      local last_line="${output_lines[-1]}"
      local check_sep="${last_line// /}"
      if [[ ! "$check_sep" =~ ^={10,}$ ]] && [[ "$last_line" != "--[[" ]]; then
        local final_sep=$(printf '=%.0s' $(seq 1 $inner_width))
        output_lines+=(" $final_sep ")
      fi
      
      output_lines+=("]]")
      
      printf '%s\n' "${output_lines[@]}"
      ;;
      
    'sql_style')
      # SQL : /* contenu */
      local inner_width=$((BLOCK_WIDTH - 5))  # " * " et ""
      
      local output_lines=()
      output_lines+=("/*")
      
      while IFS= read -r line || [[ -n "$line" ]]; do
        local trimmed="${line%"${line##*[![:space:]]}"}"
        
        if [[ "$trimmed" =~ ^[=\-]{10,}$ ]]; then
          local sep=$(printf '=%.0s' $(seq 1 $inner_width))
          output_lines+=(" * $sep")
        elif [[ -z "$trimmed" ]]; then
          output_lines+=(" * $(printf '%*s' $inner_width '')")
        else
          while IFS= read -r wrapped; do
            local formatted=$(format_line "$wrapped" "$inner_width")
            output_lines+=(" * $formatted")
          done < <(wrap_text_exact "$line" "$inner_width")
        fi
      done <<< "$content"
      
      # Ajoute le séparateur final si nécessaire
      local last_line="${output_lines[-1]}"
      local check_sep="${last_line//\* /}"
      check_sep="${check_sep// /}"
      if [[ ! "$check_sep" =~ ^={10,}$ ]] && [[ "$last_line" != "/*" ]]; then
        local final_sep=$(printf '=%.0s' $(seq 1 $inner_width))
        output_lines+=(" * $final_sep")
      fi
      
      output_lines+=(" */")
      
      printf '%s\n' "${output_lines[@]}"
      ;;
      
    'vim_style')
      # Vim : ligne unique
      local flattened=$(echo "$content" | tr '\n' ' ' | sed 's/  */ /g')
      if [[ ${#flattened} -gt $((BLOCK_WIDTH - 4)) ]]; then
        flattened="${flattened:0:$((BLOCK_WIDTH - 7))}..."
      fi
      local formatted=$(format_line "$flattened" $((BLOCK_WIDTH - 4)))
      echo "\" $formatted"
      ;;
      
    *)
      echo "$content"
      ;;
  esac
}

generate_license_text() {
  local config_file="$1"
  local format="${2:-text}"
  local include_ai_role="${3:-false}"

  if ! jq empty "$config_file" 2>/dev/null; then
    print_error "Fichier de configuration JSON invalide : $config_file"
    return 1
  fi

  local author license_type license_text copyright date_issued license_link year logo
  local ai_used ai_technique creator_role fingerprint_hash files_ext_targeted

  author=$(jq -r '.author // .authors // empty' "$config_file")
  license_type=$(jq -r '.license_type // .["license type"] // empty' "$config_file")
  license_text=$(jq -r '.license_text // .["licence text"] // empty' "$config_file")
  copyright=$(jq -r '.copyright_signs // .["copyright signs"] // "©"' "$config_file")
  date_issued=$(jq -r '.date_license_issued // .["date license issued"] // empty' "$config_file")
  license_link=$(jq -r '.license_link // .["license link"] // empty' "$config_file")
  year=$(jq -r '.year_of_licensing // .["year of licensing"] // empty' "$config_file")
  logo=$(jq -r '.logo // empty' "$config_file")

  fingerprint_hash=$(jq -r '.system_fingerprint.fingerprint_hash // "N/A"' "$config_file")
  files_ext_targeted=$(jq -r '.files_ext_targeted // "N/A"' "$config_file")

  ai_used=$(jq -r '.ai_used // "false"' "$config_file")
  ai_technique=$(jq -r '.ai_technique // empty' "$config_file")
  creator_role=$(jq -r '.creator_role // empty' "$config_file")

  local missing=()
  [[ -z "$author" ]] && missing+=("auteur(s)")
  [[ -z "$license_type" ]] && missing+=("type de licence")
  [[ -z "$license_text" ]] && missing+=("texte de licence")
  [[ -z "$copyright" ]] && missing+=("signes de copyright")
  [[ -z "$date_issued" ]] && missing+=("date d'émission de la licence")
  [[ -z "$license_link" ]] && missing+=("lien de licence")
  [[ -z "$year" ]] && missing+=("année de licence")

  local lc_license
  lc_license=$(echo "$license_type" | tr '[:upper:]' '[:lower:]')
  case "$lc_license" in
    *"creative commons"*|"cc "*|"cc-"*)
      [[ -z "$logo" ]] && missing+=("logo (obligatoire pour Creative Commons)")
      ;;
  esac

  if [[ ${#missing[@]} -gt 0 ]]; then
    print_error "Champs obligatoires manquants dans $config_file : ${missing[*]}"
    return 1
  fi

  local output=""
  case "$format" in
	'text')
	  output+="================================================================================\n"
	  output+=" INFORMATIONS DE LICENCE\n"
	  output+="================================================================================\n"
	  output+=" Auteur(s) : $author\n"
	  output+=" Type de Licence : $license_type\n"
	  output+=" Copyright : $copyright $year $author\n"
	  output+=" Date d'Émission : $date_issued\n"
	  output+=" Lien de Licence : $license_link\n"
	  if [[ "$include_ai_role" == "true" && "$ai_used" == "true" && -n "$creator_role" ]]; then
		output+=" Technique IA : $ai_technique\n"
		output+=" Rôle du Créateur : $creator_role\n"
	  fi
	  if [[ "$fingerprint_hash" != "N/A" ]]; then
		output+=" ID Système : $fingerprint_hash\n"
	  fi
	  if [[ "$files_ext_targeted" != "N/A" ]]; then
		output+=" Fichiers Cibles : $files_ext_targeted\n"
	  fi
	  output+="================================================================================\n"
	  output+="\n"
	  output+="$license_text\n"
	  [[ -n "$logo" ]] && output+="\n Logo : $logo\n"
	  ;;
    'json')
      output=$(jq -n \
        --arg author "$author" \
        --arg license_type "$license_type" \
        --arg license_text "$license_text" \
        --arg copyright "$copyright" \
        --arg date_issued "$date_issued" \
        --arg license_link "$license_link" \
        --arg year "$year" \
        --arg logo "$logo" \
        --arg fingerprint "$fingerprint_hash" \
        --arg files_ext "$files_ext_targeted" \
        '{
          author: $author,
          license_type: $license_type,
          license_text: $license_text,
          copyright: "\($copyright) \($year) \($author)",
          date_issued: $date_issued,
          license_link: $license_link,
          year: $year,
          logo: $logo,
          system_fingerprint: $fingerprint,
          files_ext_targeted: $files_ext
        }')
      ;;
  esac

  echo -e "$output"
}

#-------------------------------------------------------------------------------
# MODE INTERACTIF
#-------------------------------------------------------------------------------
interactive_mode() {
  local output_file="${1:-./.deont}"
  local advanced_mode="${2:-false}"

  print_banner
  print_info "Création du fichier de configuration .deont : $output_file"
  print_info "Mode Avancé : $advanced_mode"
  echo >&2

  local target_dir
  target_dir=$(dirname "$output_file")
  if [[ ! -w "$target_dir" ]]; then
    print_error "Impossible d'écrire dans le répertoire : $target_dir"
    return 1
  fi

  local fingerprint_json
  fingerprint_json=$(generate_system_fingerprint)
  if [[ -z "$fingerprint_json" ]] || ! echo "$fingerprint_json" | jq empty >/dev/null 2>&1; then
    print_error "Échec de la génération du JSON d'empreinte valide"
    print_info "Débogage : la sortie d'empreinte était : $fingerprint_json"
    return 1
  fi
  print_success "Empreinte générée avec succès"

  print_prompt "Entrez les extensions de fichiers cibles (séparées par des virgules, ex: js,py,css) :"
  read -r files_ext_input
  while [[ -z "$files_ext_input" ]]; do
    print_warning "Au moins une extension est requise"
    print_prompt "Entrez les extensions de fichiers cibles (séparées par des virgules) :"
    read -r files_ext_input
  done

  print_info "${COLORS[bold]}Partie 1 : Informations de Licence Obligatoires${COLORS[reset]}"
  echo "─────────────────────────────────────────" >&2

  local author=""
  while [[ -z "$author" ]]; do
    print_prompt "Entrez le(s) nom(s) d'auteur(s) :"
    read -r author
    [[ -z "$author" ]] && print_warning "L'auteur est obligatoire"
  done

  local license_type=""
  while [[ -z "$license_type" ]]; do
    print_prompt "Entrez le type de licence (MIT, GPL-3.0, Apache-2.0, CC-BY-NC-ND, etc.) :"
    read -r license_type
    [[ -z "$license_type" ]] && print_warning "Le type de licence est obligatoire"
  done

  local license_text=""
  while [[ -z "$license_text" ]]; do
    print_prompt "Entrez le texte complet de la licence (appuyez sur Ctrl+D quand terminé) :"
    license_text=$(cat)
    [[ -z "$license_text" ]] && print_warning "Le texte de licence est obligatoire"
  done

  print_prompt "Entrez le symbole de copyright (par défaut : ©) :"
  read -r copyright
  [[ -z "$copyright" ]] && copyright="©"

  local date_issued=""
  while [[ ! "$date_issued" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; do
    print_prompt "Entrez la date d'émission (AAAA-MM-JJ) :"
    read -r date_issued
    [[ ! "$date_issued" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && print_warning "Utilisez le format AAAA-MM-JJ"
  done

  local license_link=""
  while [[ -z "$license_link" ]]; do
    print_prompt "Entrez l'URL de la licence :"
    read -r license_link
    [[ -z "$license_link" ]] && print_warning "Le lien de licence est obligatoire"
  done

  local year=""
  while [[ ! "$year" =~ ^[0-9]{4}$ ]]; do
    print_prompt "Entrez l'année de licence (AAAA) :"
    read -r year
    [[ ! "$year" =~ ^[0-9]{4}$ ]] && print_warning "Utilisez le format AAAA"
  done

  local logo=""
  local lc_license
  lc_license=$(echo "$license_type" | tr '[:upper:]' '[:lower:]')
  case "$lc_license" in
    *"creative commons"*|"cc "*|"cc-"*)
      print_info "Licence Creative Commons détectée - le logo est obligatoire"
      while [[ -z "$logo" ]]; do
        print_prompt "Entrez l'URL du logo :"
        read -r logo
        [[ -z "$logo" ]] && print_warning "Le logo est obligatoire pour Creative Commons"
      done
      ;;
    *)
      print_prompt "Entrez l'URL du logo (optionnel, appuyez sur Entrée pour ignorer) :"
      read -r logo
      ;;
  esac

  local fingerprint_file="$TEMP_DIR/fingerprint.json"
  echo "$fingerprint_json" > "$fingerprint_file"

  local json_obj
  json_obj=$(jq -n \
    --arg author "$author" \
    --arg license_type "$license_type" \
    --arg license_text "$license_text" \
    --arg copyright "$copyright" \
    --arg date_issued "$date_issued" \
    --arg license_link "$license_link" \
    --arg year "$year" \
    --arg logo "$logo" \
    --arg extensions "$files_ext_input" \
    --slurpfile fingerprint "$fingerprint_file" \
    '{
      author: $author,
      license_type: $license_type,
      license_text: $license_text,
      copyright_signs: $copyright,
      date_license_issued: $date_issued,
      license_link: $license_link,
      year_of_licensing: $year,
      logo: $logo,
      files_ext_targeted: $extensions,
      system_fingerprint: $fingerprint[0]
    }')

  if [[ -z "$json_obj" ]]; then
    print_error "Échec de la création de l'objet JSON de base"
    return 1
  fi

  if [[ "$advanced_mode" == "true" ]]; then
    echo >&2
    print_info "${COLORS[bold]}Partie 2 : Champs de Documentation Avancés${COLORS[reset]}"
    echo "─────────────────────────────────────────" >&2

    local ai_used=""
    while true; do
      print_prompt "Une IA a-t-elle été utilisée dans la création de cette œuvre ? (Oui/Non) :"
      read -r ai_used
      ai_used=$(echo "$ai_used" | tr '[:upper:]' '[:lower:]')
      case "$ai_used" in
        'oui'|'o'|'yes'|'y'|'non'|'n'|'no') break ;;
        *) print_warning "Veuillez répondre Oui ou Non" ;;
      esac
    done

    local ai_bool="false"
    [[ "$ai_used" =~ ^(oui|o|yes|y)$ ]] && ai_bool="true"

    local ai_technique=""
    local manager_note=""
    local creator_role=""

    if [[ "$ai_used" =~ ^(oui|o|yes|y)$ ]]; then
      echo >&2
      print_info "Sélectionnez la technique de programmation IA :"
      echo " 1) MCP (Model Context Protocol)" >&2
      echo " 2) Prompting" >&2
      echo " 3) Chaîne De Prompt MCP" >&2
      echo " 4) Chaînes de prompt" >&2
      echo " 5) Mixte" >&2
      echo " 6) Autre (préciser)" >&2

      while [[ -z "$ai_technique" ]]; do
        print_prompt "Entrez le choix (1-6) :"
        read -r choice
        case "$choice" in
          1) ai_technique="MCP" ;;
          2) ai_technique="Prompting" ;;
          3) ai_technique="Chaîne De Prompt MCP" ;;
          4) ai_technique="Chaînes de prompt" ;;
          5) ai_technique="Mixte" ;;
          6) print_prompt "Veuillez préciser la technique :"; read -r ai_technique ;;
          *) print_warning "Choix invalide" ;;
        esac
      done

      print_prompt "Entrez les notes du gestionnaire (max 10000 caractères, appuyez sur Ctrl+D quand terminé) :"
      manager_note=$(cat)
      manager_note=${manager_note:0:10000}

      print_prompt "Entrez le rôle du créateur (max 5000 caractères) :"
      read -r creator_role
      creator_role=${creator_role:0:5000}
    fi

    json_obj=$(echo "$json_obj" | jq \
      --arg ai_bool "$ai_bool" \
      --arg ai_technique "$ai_technique" \
      --arg manager_note "$manager_note" \
      --arg creator_role "$creator_role" \
      '. + {
        ai_used: ($ai_bool == "true"),
        ai_technique: $ai_technique,
        manager_note: $manager_note,
        creator_role: $creator_role
      }')
  fi

  if echo "$json_obj" | jq '.' > "$output_file" 2>"$TEMP_DIR/jq_error.log"; then
    print_success "Configuration enregistrée dans : $output_file"
    if [[ -s "$output_file" ]]; then
      print_info "Taille du fichier : $(wc -c < "$output_file") octets"
      return 0
    fi
    print_error "Le fichier a été créé mais est vide"
    return 1
  fi

  print_error "Échec de la création d'un JSON valide"
  [[ -f "$TEMP_DIR/jq_error.log" ]] && { print_error "Erreur JQ :"; cat "$TEMP_DIR/jq_error.log" >&2; }
  return 1
}

#-------------------------------------------------------------------------------
# MODE APPLICATION
#-------------------------------------------------------------------------------
apply_license() {
  local config_file="$1"
  local recursive="${2:-true}"
  local target="${3:-.}"
  local specific_file="${4:-}"

  if [[ ! -f "$config_file" ]]; then
    print_error "Fichier de configuration non trouvé : $config_file"
    return 1
  fi
  if ! jq empty "$config_file" 2>/dev/null; then
    print_error "JSON invalide dans le fichier de config : $config_file"
    return 1
  fi

  local files_ext_targeted
  files_ext_targeted=$(jq -r '.files_ext_targeted // empty' "$config_file")
  if [[ -z "$files_ext_targeted" ]]; then
    print_error "Aucune extension cible spécifiée dans la config (files_ext_targeted)"
    return 1
  fi

  local advanced_mode="false"
  local ai_used creator_role
  ai_used=$(jq -r '.ai_used // "false"' "$config_file")
  creator_role=$(jq -r '.creator_role // empty' "$config_file")
  if [[ "$ai_used" == "true" && -n "$creator_role" ]]; then
    advanced_mode="true"
    print_info "Mode avancé détecté - Le rôle IA sera inclus dans les en-têtes de licence"
  fi

  # Vérifie si la cible est un fichier ou un répertoire
  if [[ -f "$target" ]]; then
    specific_file="$target"
    target=$(dirname "$target")
    print_info "Mode fichier unique : $specific_file"
  else
    print_info "Mode répertoire : $target (Récursif : $recursive)"
  fi

  print_info "Application de la licence depuis $config_file"
  print_info "Extensions cibles : $files_ext_targeted"

  IFS=',' read -ra EXTENSIONS <<< "$files_ext_targeted"
  local total_count=0

  for ext in "${EXTENSIONS[@]}"; do
    ext=$(echo "$ext" | xargs)
    [[ -z "$ext" ]] && continue

    # Si un fichier spécifique est fourni, vérifie s'il correspond à cette extension
    if [[ -n "$specific_file" ]]; then
      if [[ ! "$specific_file" =~ \.$ext$ ]]; then
        continue
      fi
      local files_to_process=("$specific_file")
    else
      local find_args=("$target" "-type" "f" "-name" "*.$ext")
      [[ "$recursive" != "true" ]] && find_args=("$target" "-maxdepth" "1" "-type" "f" "-name" "*.$ext")
      
      local files_to_process=()
      while IFS= read -r -d '' file; do
        files_to_process+=("$file")
      done < <(find "${find_args[@]}" -print0 2>/dev/null)
    fi

    [[ ${#files_to_process[@]} -eq 0 ]] && continue

    print_info "Traitement des fichiers *.$ext..."

    local license_content
    license_content=$(generate_license_text "$config_file" "text" "$advanced_mode") || continue

    local comment_style formatted_header
    comment_style=$(get_comment_style "$ext")
    formatted_header=$(format_comment_block "$comment_style" "$license_content")

    local count=0
    for file in "${files_to_process[@]}"; do
      if [[ ! -f "$file" ]]; then
        print_error "Fichier non trouvé : $file"
        continue
      fi

      if head -n 5 "$file" 2>/dev/null | grep -q "INFORMATIONS DE LICENCE"; then
        print_warning "Ignoré (licence déjà présente) : $file"
        continue
      fi

      local temp_file="$TEMP_DIR/$(basename "$file").tmp"
      
      # Traitement spécial pour les fichiers HTML - insertion entre <html> et <head>
      if [[ "$ext" == "html" ]] || [[ "$ext" == "htm" ]]; then
        if grep -qi "<html" "$file"; then
          # Crée le motif : trouve <html>, puis insère avant <head> ou la balise suivante
          awk -v header="$formatted_header" '
            /<html[^>]*>/ {
              print
              # Lit les lignes jusqu'à trouver <head> ou un contenu non vide
              while ((getline line) > 0) {
                if (line ~ /<head/i || line ~ /<body/i || line ~ /<\?/ || line ~ /<![a-z]/i) {
                  # Balise cible trouvée, insère l'en-tête avant
                  print header
                  print line
                  break
                } else if (line ~ /^[[:space:]]*$/) {
                  # Ligne vide, ignore (ne conserve pas les nouvelles lignes supplémentaires)
                  continue
                } else {
                  # Autre contenu, insère l'en-tête et affiche cette ligne
                  print header
                  print line
                  break
                }
              }
              next
            }
            { print }
          ' "$file" > "$temp_file"
        else
          {
            echo "$formatted_header"
            cat "$file"
          } > "$temp_file"
        fi
      else
        # Traitement standard pour les autres fichiers
        local first_line
        first_line=$(head -n 1 "$file")
        
        if [[ "$first_line" =~ ^#! ]]; then
          # Shebang trouvé - le conserve en haut
          {
            echo "$first_line"
            echo ""
            echo "$formatted_header"
            echo ""
            tail -n +2 "$file"
          } > "$temp_file"
        else
          # Pas de shebang, préfixe la licence
          {
            echo "$formatted_header"
            echo ""
            cat "$file"
          } > "$temp_file"
        fi
      fi

      if mv "$temp_file" "$file"; then
        print_success "Licencié : $file"
        ((count++))
        ((total_count++))
      else
        print_error "Échec : $file"
      fi
    done

    print_success "$count fichier(s) *.$ext traité(s)"
  done

  print_success "Total de fichiers traités : $total_count"
}

#-------------------------------------------------------------------------------
# GÉNÉRATION DE RAPPORT PDF
#-------------------------------------------------------------------------------
generate_latex_report() {
  local config_file="$1"
  local output_file="$2"
  local pdf_only="${3:-false}"

  if [[ ! -f "$config_file" ]]; then
    print_error "Fichier de configuration non trouvé : $config_file"
    return 1
  fi
  if ! jq empty "$config_file" 2>/dev/null; then
    print_error "JSON invalide dans le fichier de config : $config_file"
    return 1
  fi

  print_info "Génération du rapport depuis $config_file..."

  local tex_file
  if [[ "$output_file" == *.tex ]]; then
    tex_file="$output_file"
    output_file="${output_file%.tex}"
  elif [[ "$output_file" == *.pdf ]]; then
    output_file="${output_file%.pdf}"
    tex_file="${output_file}.tex"
  else
    tex_file="${output_file}.tex"
  fi
  local pdf_file="${output_file}.pdf"

  local author license_type copyright date_issued license_link year logo
  local ai_used ai_technique manager_note creator_role
  local fingerprint_hash fp_hostname fp_timestamp
  local files_ext_targeted full_license_text

  author=$(jq -r '.author // .authors // "Inconnu"' "$config_file")
  license_type=$(jq -r '.license_type // .["license type"] // "Non spécifié"' "$config_file")
  copyright=$(jq -r '.copyright_signs // .["copyright signs"] // "©"' "$config_file")
  date_issued=$(jq -r '.date_license_issued // .["date license issued"] // "N/A"' "$config_file")
  license_link=$(jq -r '.license_link // .["license link"] // "N/A"' "$config_file")
  year=$(jq -r '.year_of_licensing // .["year of licensing"] // "N/A"' "$config_file")
  logo=$(jq -r '.logo // empty' "$config_file")
  files_ext_targeted=$(jq -r '.files_ext_targeted // "N/A"' "$config_file")
  ai_used=$(jq -r '.ai_used // "N/A"' "$config_file")
  ai_technique=$(jq -r '.ai_technique // "N/A"' "$config_file")
  manager_note=$(jq -r '.manager_note // "N/A"' "$config_file")
  creator_role=$(jq -r '.creator_role // "N/A"' "$config_file")
  fingerprint_hash=$(jq -r '.system_fingerprint.fingerprint_hash // "N/A"' "$config_file")
  fp_hostname=$(jq -r '.system_fingerprint.system_info.hostname // "N/A"' "$config_file")
  fp_timestamp=$(jq -r '.system_fingerprint.generated_at // "N/A"' "$config_file")
  full_license_text=$(jq -r '.license_text // .["licence text"] // "Aucun texte de licence fourni."' "$config_file")

  case "$ai_used" in
    'true') ai_used="Oui" ;;
    'false') ai_used="Non" ;;
  esac

  author=$(echo "$author" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g; s/{/\\{/g; s/}/\\}/g; s/~/\$\\sim\$/g; s/\^/\\^/g')
  license_type=$(echo "$license_type" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g; s/{/\\{/g; s/}/\\}/g')
  manager_note=$(echo "$manager_note" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g; s/{/\\{/g; s/}/\\}/g')
  creator_role=$(echo "$creator_role" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g; s/{/\\{/g; s/}/\\}/g')

  cat > "$tex_file" << EOF
\\documentclass[12pt,a4paper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{geometry}
\\usepackage{booktabs}
\\usepackage{longtable}
\\usepackage{array}
\\usepackage{hyperref}
\\usepackage{fancyhdr}
\\usepackage{xcolor}
\\usepackage{verbatim}
\\usepackage{enumitem}
\\usepackage{fancyvrb}
\\usepackage{breakurl}
\\usepackage{ragged2e}
\\geometry{margin=2.5cm}
\\pagestyle{fancy}
\\fancyhf{}
\\rhead{Rapport de Licence}
\\lhead{LHF v$VERSION}
\\rfoot{Page \\thepage}
\\title{\\textbf{Rapport de Documentation de Licence}\\\\\\Large Généré par LHF v$VERSION}
\\author{Cadre Déontologique}
\\date{\\today}
\\begin{document}
\\maketitle

\\section{Aperçu de la Licence}
\\begin{table}[h]
\\centering
\\renewcommand{\\arraystretch}{1.3}
\\begin{tabular}{@{}>{\\bfseries}l p{10cm}@{}}
\\toprule
Champ & Valeur \\\\
\\midrule
Auteur(s) & $author \\\\
Type de Licence & $license_type \\\\
Copyright & $copyright $year $author \\\\
Date d'Émission & $date_issued \\\\
Lien de Licence & \\url{$license_link} \\\\
Année de Licence & $year \\\\
Fichiers Cibles & $files_ext_targeted \\\\
\\bottomrule
\\end{tabular}
\\caption{Informations Principales de Licence}
\\end{table}

\\subsection{Avis de Copyright}
Le symbole de copyright $copyright indique que $author conserve les droits de propriété intellectuelle pour l'année $year.
EOF

  if [[ "$fingerprint_hash" != "N/A" ]]; then
    cat >> "$tex_file" << EOF

\\section{Empreinte Système}
Ce document a été généré avec un identifiant système unique à des fins de traçabilité.
\\begin{table}[h]
\\centering
\\renewcommand{\\arraystretch}{1.3}
\\begin{tabular}{@{}>{\\bfseries}l p{10cm}@{}}
\\toprule
Propriété & Valeur \\\\
\\midrule
Hash d'Empreinte & \\texttt{$fingerprint_hash} \\\\
Généré Le & $fp_timestamp \\\\
Nom d'Hôte & $fp_hostname \\\\
\\bottomrule
\\end{tabular}
\\caption{Identification Système}
\\end{table}
EOF
  fi

  if [[ "$ai_used" != "N/A" ]]; then
    cat >> "$tex_file" << EOF

\\section{Section IA}
\\begin{table}[h]
\\centering
\\renewcommand{\\arraystretch}{1.3}
\\begin{tabular}{@{}>{\\bfseries}l p{10cm}@{}}
\\toprule
Aspect & Détails \\\\
\\midrule
IA Utilisée & $ai_used \\\\
EOF

    if [[ "$ai_used" == "Oui" && "$ai_technique" != "N/A" ]]; then
      cat >> "$tex_file" << EOF
Technique IA & $ai_technique \\\\
EOF
    fi

    cat >> "$tex_file" << EOF
\\bottomrule
\\end{tabular}
\\caption{Informations d'Utilisation de l'IA}
\\end{table}
EOF

    if [[ "$ai_used" == "Oui" && "$ai_technique" != "N/A" ]]; then
      cat >> "$tex_file" << EOF

\\subsection{Approche Technique}
Le développement de cette œuvre a employé \\textbf{$ai_technique} comme méthodologie principale de programmation IA.
EOF
    fi
  fi

  if [[ "$creator_role" != "N/A" && -n "$creator_role" ]]; then
    cat >> "$tex_file" << EOF

\\section{Personnel et Responsabilités}
\\subsection{Rôle du Créateur}
\\begin{quote}
$creator_role
\\end{quote}
EOF
  fi

  if [[ "$manager_note" != "N/A" && -n "$manager_note" ]]; then
    cat >> "$tex_file" << EOF

\\section{Notes Administratives}
\\subsection{Observations Managériales}
\\begin{quote}
$manager_note
\\end{quote}
EOF
  fi

  if [[ -n "$logo" && "$logo" != "null" && "$logo" != "N/A" ]]; then
    cat >> "$tex_file" << EOF

\\section{Identité Visuelle}
\\begin{center}
\\url{$logo}
\\end{center}
EOF
  fi

  cat >> "$tex_file" << 'LATEX_LEGAL'
\section{Texte Légal}
\begin{center}
\textit{Le texte légal complet de la licence est fourni ci-dessous :}
\end{center}
\vspace{0.5cm}
\noindent\begin{minipage}{\textwidth}
\setlength{\parskip}{0.5em}
\setlength{\parindent}{0pt}
\fontsize{9}{11}\selectfont
\ttfamily
\raggedright
LATEX_LEGAL

  echo "$full_license_text" | sed \
    -e 's/\\/\\\\/g' \
    -e 's/{/\\{/g' \
    -e 's/}/\\}/g' \
    -e 's/\$/\\$/g' \
    -e 's/%/\\%/g' \
    -e 's/#/\\#/g' \
    -e 's/_/\\_/g' \
    -e 's/&/\\&/g' \
    >> "$tex_file"

  cat >> "$tex_file" << EOF

\\end{minipage}
\\vfill
\\begin{center}
\\textit{Ce rapport a été généré automatiquement par le Cadre d'En-tête de Licence v$VERSION}\\\\
\\textit{Version du Document : $DEONT_VERSION | Date de Génération : \\today}\\\\
Empreinte Système : \\texttt{$fingerprint_hash}
\\end{center}
\\end{document}
EOF

  print_success "Source LaTeX générée : $tex_file"

  if command -v pdflatex &> /dev/null; then
    print_info "Compilation du PDF..."
    local tex_dir tex_name
    tex_dir=$(dirname "$tex_file")
    tex_name=$(basename "$tex_file")
    (cd "$tex_dir" && pdflatex -interaction=nonstopmode "$tex_name" > /dev/null 2>&1)
    (cd "$tex_dir" && pdflatex -interaction=nonstopmode "$tex_name" > /dev/null 2>&1)

    if [[ -f "$pdf_file" ]]; then
      print_success "PDF généré : $pdf_file"
      rm -f "${tex_file%.tex}.aux" "${tex_file%.tex}.log" "${tex_file%.tex}.out"
      [[ "$pdf_only" == "true" ]] && rm -f "$tex_file"
      return 0
    fi

    print_error "Échec de la compilation PDF"
    return 1
  fi

  print_warning "pdflatex non trouvé. Installez texlive-full pour générer le PDF."
  print_info "Source LaTeX enregistrée : $tex_file"
  return 1
}

#-------------------------------------------------------------------------------
# AIDE
#-------------------------------------------------------------------------------
show_help() {
  cat << EOF
Cadre d'En-tête de Licence (LHF) v$VERSION

UTILISATION :
./$SCRIPT_NAME [COMMANDE] [OPTIONS]

COMMANDES :
  init       Initialiser le répertoire de configuration
  create     Créer le fichier .deont (interactif par défaut)
  apply      Appliquer les en-têtes de licence aux fichiers via .deont
  report     Générer un rapport PDF depuis .deont
  validate   Valider le fichier .deont

OPTIONS :
  -f, --file FICHIER      Chemin du fichier .deont (défaut : ./.deont)
  -a, --author NOM        Nom de l'auteur (pour création rapide)
  -l, --license TYPE      Type de licence (MIT, GPL, etc.)
  -t, --text TEXTE        Texte de licence (ou @fichier.txt)
  -d, --date DATE         Date d'émission (AAAA-MM-JJ)
  -y, --year ANNÉE        Année de licence
  -u, --url URL           URL de la licence
  -e, --extensions EXT    Extensions cibles (séparées par des virgules)
  -r, --recursive         Mode récursif pour apply
  --dir RÉPERTOIRE        Répertoire cible (défaut : .)
  --advanced              Activer les champs avancés (IA, empreinte)
  --pdf-only              Générer uniquement le PDF
  -h, --help              Afficher l'aide
  -v, --version           Afficher la version

EXEMPLES :
  ./$SCRIPT_NAME create --advanced
  ./$SCRIPT_NAME apply -f .deont -r --dir ./src
  ./$SCRIPT_NAME report -f .deont --pdf-only
EOF
}

#-------------------------------------------------------------------------------
# PRINCIPAL
#-------------------------------------------------------------------------------
main() {
  create_temp_dir
  check_dependencies

  local command=""
  local deont_file="./.deont"

  local author=""
  local license_type=""
  local license_text=""
  local date_issued=""
  local license_link=""
  local year=""
  local logo=""
  local extensions=""
  local recursive="false"
  local target_dir="."
  local advanced="false"
  local pdf_only="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      init|create|apply|report|validate) command="$1"; shift 1 ;;
      -f|--file) deont_file="$2"; shift 2 ;;
      -a|--author) author="$2"; shift 2 ;;
      -l|--license) license_type="$2"; shift 2 ;;
      -t|--text) license_text="$2"; shift 2 ;;
      -d|--date) date_issued="$2"; shift 2 ;;
      -u|--url) license_link="$2"; shift 2 ;;
      -y|--year) year="$2"; shift 2 ;;
      --logo) logo="$2"; shift 2 ;;
      -e|--extensions) extensions="$2"; shift 2 ;;
      -r|--recursive) recursive="true"; shift 1 ;;
      --dir) target_dir="$2"; shift 2 ;;
      --advanced) advanced="true"; shift 1 ;;
      --pdf-only) pdf_only="true"; shift 1 ;;
      -h|--help) show_help; exit 0 ;;
      -v|--version) echo "$SCRIPT_NAME version $VERSION"; exit 0 ;;
      *) print_error "Option inconnue : $1"; show_help; exit 1 ;;
    esac
  done

  case "$command" in
    'init')
      mkdir -p "$DEFAULT_CONFIG_DIR" "$TEMPLATES_DIR"
      print_success "LHF initialisé à $DEFAULT_CONFIG_DIR"
      ;;
    'create')
      if [[ -n "$author" && -n "$license_type" && -n "$license_text" && -n "$year" && -n "$extensions" ]]; then
        print_info "Création rapide du fichier .deont : $deont_file"

        if [[ "$license_text" == @* ]]; then
          local text_file="${license_text#@}"
          if [[ -f "$text_file" ]]; then
            license_text=$(cat "$text_file")
          else
            print_error "Fichier de texte de licence non trouvé : $text_file"
            exit 1
          fi
        fi

        [[ -z "$date_issued" ]] && date_issued=$(date +%Y-%m-%d)
        [[ -z "$license_link" ]] && license_link="https://opensource.org/licenses/  $license_type"
        [[ -z "$logo" ]] && logo=""

        local fingerprint_json
        fingerprint_json=$(generate_system_fingerprint)
        if [[ -z "$fingerprint_json" ]] || ! echo "$fingerprint_json" | jq empty >/dev/null 2>&1; then
          print_error "Échec de la génération d'une empreinte valide"
          exit 1
        fi

        local fingerprint_file="$TEMP_DIR/fingerprint.json"
        echo "$fingerprint_json" > "$fingerprint_file"

        if jq -n \
          --arg author "$author" \
          --arg license_type "$license_type" \
          --arg license_text "$license_text" \
          --arg copyright "©" \
          --arg date_issued "$date_issued" \
          --arg license_link "$license_link" \
          --arg year "$year" \
          --arg logo "$logo" \
          --arg extensions "$extensions" \
          --slurpfile fingerprint "$fingerprint_file" \
          '{
            author: $author,
            license_type: $license_type,
            license_text: $license_text,
            copyright_signs: $copyright,
            date_license_issued: $date_issued,
            license_link: $license_link,
            year_of_licensing: $year,
            logo: $logo,
            files_ext_targeted: $extensions,
            system_fingerprint: $fingerprint[0]
          }' > "$deont_file"; then
          print_success "Créé : $deont_file"
        else
          print_error "Échec de la création du fichier .deont"
          exit 1
        fi
      else
        interactive_mode "$deont_file" "$advanced"
      fi
      ;;
    'apply')
      apply_license "$deont_file" "$recursive" "$target_dir"
      ;;
    'report')
      local report_file="${deont_file%.deont}_report"
      generate_latex_report "$deont_file" "$report_file" "$pdf_only"
      ;;
    'validate')
      if generate_license_text "$deont_file" > /dev/null; then
        print_success "Le fichier .deont est valide : $deont_file"
      else
        print_error "Validation échouée pour : $deont_file"
        exit 1
      fi
      ;;
    '')
      print_banner
      show_help
      ;;
    *)
      print_error "Commande inconnue : $command"
      exit 1
      ;;
  esac
}

main "$@"
