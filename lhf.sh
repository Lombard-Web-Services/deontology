# ================================================================================
#  LICENSE INFORMATION
# ================================================================================
#  Author(s): Thibaut LOMBARD (LombardWeb)
#  License Type: MIT
#  Copyright: © 2026 Thibaut LOMBARD (LombardWeb)
#  Date Issued: 2026-02-21
#  License Link: https://opensource.org/license/mit
#  AI Technique: Prompting
#  Creator Role: Project Manager and Software Architect , Machine Learning Engineer
#  System ID: a15fbc9745ea0cfa
#  Target Files: sh
# ================================================================================
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#!/bin/bash
#===============================================================================
# LICENSE HEADER FRAMEWORK (LHF)
# Version: 2.0.5 - Fix fingerprint JSON capture (stdout vs stderr) + structure fixes
#===============================================================================

set -o pipefail

readonly SCRIPT_NAME="lhf"
readonly VERSION="2.0.5"
readonly DEONT_VERSION="2.0"
readonly DEFAULT_CONFIG_DIR="$HOME/.config/lhf"
readonly TEMPLATES_DIR="$DEFAULT_CONFIG_DIR/templates"
readonly TEMP_DIR="/tmp/lhf_$$"

# Color codes
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

# Comment styles
declare -A COMMENT_STYLES=(
  ['sh']='hash' ['bash']='hash' ['zsh']='hash' ['py']='hash' ['rb']='hash'
  ['pl']='hash' ['yaml']='hash' ['yml']='hash' ['conf']='hash'
  ['dockerfile']='hash' ['makefile']='hash'
  ['c']='c_style' ['cpp']='c_style' ['h']='c_style' ['hpp']='c_style'
  ['java']='c_style' ['js']='c_style' ['ts']='c_style' ['css']='c_style'
  ['scss']='c_style' ['go']='c_style' ['rs']='c_style' ['swift']='c_style'
  ['kt']='c_style'
  ['html']='html_style' ['xml']='html_style' ['svg']='html_style' ['md']='html_style'
  ['lua']='lua_style' ['sql']='sql_style' ['vim']='vim_style'
)

#-------------------------------------------------------------------------------
# UTILITY FUNCTIONS
#-------------------------------------------------------------------------------

print_banner() {
  echo -e "${COLORS[cyan]}"
  cat << 'EOF'

╔═══════════════════════════════════════════════════════════════╗
║           📜  LICENSE HEADER FRAMEWORK (LHF)  📜              ║
║         System Fingerprint & Enhanced PDF Generation          ║
╚═══════════════════════════════════════════════════════════════╝

EOF
  echo -e "${COLORS[reset]}"
}

# IMPORTANT: send logs to stderr so JSON-producing functions can use stdout safely.
print_error()   { echo -e "${COLORS[red]}[ERROR]${COLORS[reset]} $1" >&2; }
print_success() { echo -e "${COLORS[green]}[SUCCESS]${COLORS[reset]} $1" >&2; }
print_info()    { echo -e "${COLORS[blue]}[INFO]${COLORS[reset]} $1" >&2; }
print_warning() { echo -e "${COLORS[yellow]}[WARNING]${COLORS[reset]} $1" >&2; }
print_prompt()  { echo -e "${COLORS[magenta]}➜${COLORS[reset]} ${COLORS[bold]}$1${COLORS[reset]}" >&2; }

check_dependencies() {
  print_info "Checking dependencies..."
  if ! command -v jq &> /dev/null; then
    print_error "Missing required dependency: jq"
    print_info "Install with: sudo apt-get install jq"
    exit 1
  fi
  print_success "All dependencies satisfied"
}

create_temp_dir() {
  mkdir -p "$TEMP_DIR"
  if [[ ! -d "$TEMP_DIR" ]]; then
    print_error "Failed to create temp directory"
    exit 1
  fi
  trap 'rm -rf "$TEMP_DIR"' EXIT
}

#-------------------------------------------------------------------------------
# SYSTEM FINGERPRINT (stdout must be JSON only)
#-------------------------------------------------------------------------------
generate_system_fingerprint() {
  # Log to stderr (NOT stdout), so callers capturing stdout get pure JSON.
  print_info "Generating unique system fingerprint..."

  local data=""
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # 1. System identifiers
  if [[ -f /etc/machine-id ]]; then
    data+="MACHINE_ID:$(cat /etc/machine-id 2>/dev/null)\n"
  fi
  if [[ -f /var/lib/dbus/machine-id ]]; then
    data+="DBUS_ID:$(cat /var/lib/dbus/machine-id 2>/dev/null)\n"
  fi

  # 2. DMI Hardware
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

  # 3. MAC addresses
  for mac in /sys/class/net/*/address; do
    if [[ -r "$mac" ]]; then
      local mac_addr
      mac_addr=$(cat "$mac" 2>/dev/null)
      data+="MAC:${mac_addr}\n"
    fi
  done

  # 4. Disk UUIDs
  while read -r uuid; do
    if [[ -n "$uuid" ]]; then
      data+="DISK_UUID:${uuid}\n"
    fi
  done < <(lsblk -o UUID -n 2>/dev/null | sort -u)

  # 5. CPU info
  local cpu_model
  cpu_model=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
  if [[ -n "$cpu_model" ]]; then
    cpu_model=$(echo "$cpu_model" | sed 's/\\/\\\\/g; s/"/\\"/g')
    data+="CPU_MODEL:${cpu_model}\n"
  fi

  local cpu_cores
  cpu_cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo "0")
  data+="CPU_CORES:${cpu_cores}\n"

  # Hash
  local fingerprint_hash
  fingerprint_hash=$(echo -e "$data" | sha256sum | awk '{print $1}')
  fingerprint_hash="${fingerprint_hash:0:16}"

  # Hostname
  local hostname_val
  hostname_val=$(hostname 2>/dev/null || echo "unknown")

  # Output: JSON only on stdout
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
# CORE FUNCTIONS
#-------------------------------------------------------------------------------
get_comment_style() {
  local extension="$1"
  echo "${COMMENT_STYLES[$extension]:-hash}"
}

format_comment_block() {
  local style="$1"
  local content="$2"
  local width=78
  local border
  border=$(printf '=%.0s' $(seq 1 $((width-2))))

  case "$style" in
    'hash')
      echo "$content" | while IFS= read -r line; do printf "# %s\n" "$line"; done
      ;;
    'c_style')
      echo "/*${border}*/"
      echo "$content" | while IFS= read -r line; do printf " * %-76s *\n" "$line"; done
      echo "/*${border}*/"
      ;;
    'html_style')
      echo "<!--"
      echo "$content"
      echo "-->"
      ;;
    'lua_style')
      echo "--[["
      echo "$content" | while IFS= read -r line; do echo " $line"; done
      echo "--]]"
      ;;
    'sql_style')
      echo "/*"
      echo "$content" | while IFS= read -r line; do echo " * $line"; done
      echo " */"
      ;;
    'vim_style')
      echo "\" $(echo "$content" | tr '\n' ' ')"
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
    print_error "Invalid JSON configuration file: $config_file"
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
  [[ -z "$author" ]] && missing+=("author(s)")
  [[ -z "$license_type" ]] && missing+=("license type")
  [[ -z "$license_text" ]] && missing+=("license text")
  [[ -z "$copyright" ]] && missing+=("copyright signs")
  [[ -z "$date_issued" ]] && missing+=("date license issued")
  [[ -z "$license_link" ]] && missing+=("license link")
  [[ -z "$year" ]] && missing+=("year of licensing")

  local lc_license
  lc_license=$(echo "$license_type" | tr '[:upper:]' '[:lower:]')
  case "$lc_license" in
    *"creative commons"*|"cc "*|"cc-"*)
      [[ -z "$logo" ]] && missing+=("logo (mandatory for Creative Commons)")
      ;;
  esac

  if [[ ${#missing[@]} -gt 0 ]]; then
    print_error "Missing mandatory fields in $config_file: ${missing[*]}"
    return 1
  fi

  local output=""
  case "$format" in
    'text')
      output+="================================================================================\n"
      output+=" LICENSE INFORMATION\n"
      output+="================================================================================\n"
      output+=" Author(s): $author\n"
      output+=" License Type: $license_type\n"
      output+=" Copyright: $copyright $year $author\n"
      output+=" Date Issued: $date_issued\n"
      output+=" License Link: $license_link\n"
      if [[ "$include_ai_role" == "true" && "$ai_used" == "true" && -n "$creator_role" ]]; then
        output+=" AI Technique: $ai_technique\n"
        output+=" Creator Role: $creator_role\n"
      fi
      if [[ "$fingerprint_hash" != "N/A" ]]; then
        output+=" System ID: $fingerprint_hash\n"
      fi
      if [[ "$files_ext_targeted" != "N/A" ]]; then
        output+=" Target Files: $files_ext_targeted\n"
      fi
      output+="================================================================================\n\n"
      output+="$license_text\n"
      [[ -n "$logo" ]] && output+="\n Logo: $logo\n"
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
# INTERACTIVE MODE
#-------------------------------------------------------------------------------
interactive_mode() {
  local output_file="${1:-./.deont}"
  local advanced_mode="${2:-false}"

  print_banner
  print_info "Creating .deont configuration file: $output_file"
  print_info "Advanced Mode: $advanced_mode"
  echo >&2

  local target_dir
  target_dir=$(dirname "$output_file")
  if [[ ! -w "$target_dir" ]]; then
    print_error "Cannot write to directory: $target_dir"
    return 1
  fi

  local fingerprint_json
  fingerprint_json=$(generate_system_fingerprint)   # pure JSON on stdout now
  if [[ -z "$fingerprint_json" ]] || ! echo "$fingerprint_json" | jq empty >/dev/null 2>&1; then
    print_error "Failed to generate valid fingerprint JSON"
    print_info "Debug: fingerprint output was: $fingerprint_json"
    return 1
  fi
  print_success "Fingerprint generated successfully"

  print_prompt "Enter target file extensions (comma-separated, e.g., js,py,css):"
  read -r files_ext_input
  while [[ -z "$files_ext_input" ]]; do
    print_warning "At least one extension is required"
    print_prompt "Enter target file extensions (comma-separated):"
    read -r files_ext_input
  done

  print_info "${COLORS[bold]}Part 1: Mandatory License Information${COLORS[reset]}"
  echo "─────────────────────────────────────────" >&2

  local author=""
  while [[ -z "$author" ]]; do
    print_prompt "Enter author name(s):"
    read -r author
    [[ -z "$author" ]] && print_warning "Author is required"
  done

  local license_type=""
  while [[ -z "$license_type" ]]; do
    print_prompt "Enter license type (MIT, GPL-3.0, Apache-2.0, CC-BY-NC-ND, etc.):"
    read -r license_type
    [[ -z "$license_type" ]] && print_warning "License type is required"
  done

  local license_text=""
  while [[ -z "$license_text" ]]; do
    print_prompt "Enter full license text (press Ctrl+D when done):"
    license_text=$(cat)
    [[ -z "$license_text" ]] && print_warning "License text is required"
  done

  print_prompt "Enter copyright symbol (default: ©):"
  read -r copyright
  [[ -z "$copyright" ]] && copyright="©"

  local date_issued=""
  while [[ ! "$date_issued" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; do
    print_prompt "Enter date issued (YYYY-MM-DD):"
    read -r date_issued
    [[ ! "$date_issued" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && print_warning "Use format YYYY-MM-DD"
  done

  local license_link=""
  while [[ -z "$license_link" ]]; do
    print_prompt "Enter license URL:"
    read -r license_link
    [[ -z "$license_link" ]] && print_warning "License link is required"
  done

  local year=""
  while [[ ! "$year" =~ ^[0-9]{4}$ ]]; do
    print_prompt "Enter year of licensing (YYYY):"
    read -r year
    [[ ! "$year" =~ ^[0-9]{4}$ ]] && print_warning "Use format YYYY"
  done

  local logo=""
  local lc_license
  lc_license=$(echo "$license_type" | tr '[:upper:]' '[:lower:]')
  case "$lc_license" in
    *"creative commons"*|"cc "*|"cc-"*)
      print_info "Creative Commons license detected - logo is mandatory"
      while [[ -z "$logo" ]]; do
        print_prompt "Enter logo URL:"
        read -r logo
        [[ -z "$logo" ]] && print_warning "Logo is required for Creative Commons"
      done
      ;;
    *)
      print_prompt "Enter logo URL (optional, press Enter to skip):"
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
    print_error "Failed to create base JSON object"
    return 1
  fi

  if [[ "$advanced_mode" == "true" ]]; then
    echo >&2
    print_info "${COLORS[bold]}Part 2: Advanced Documentation Fields${COLORS[reset]}"
    echo "─────────────────────────────────────────" >&2

    local ai_used=""
    while true; do
      print_prompt "Was AI used in the creation of this work? (Yes/No):"
      read -r ai_used
      ai_used=$(echo "$ai_used" | tr '[:upper:]' '[:lower:]')
      case "$ai_used" in
        'yes'|'y'|'no'|'n') break ;;
        *) print_warning "Please answer Yes or No" ;;
      esac
    done

    local ai_bool="false"
    [[ "$ai_used" =~ ^(yes|y)$ ]] && ai_bool="true"

    local ai_technique=""
    local manager_note=""
    local creator_role=""

    if [[ "$ai_used" =~ ^(yes|y)$ ]]; then
      echo >&2
      print_info "Select AI programming technique:"
      echo " 1) MCP (Model Context Protocol)" >&2
      echo " 2) Prompting" >&2
      echo " 3) Chain Of Prompt MCP" >&2
      echo " 4) Chains of prompt" >&2
      echo " 5) Mixed" >&2
      echo " 6) Other (specify)" >&2

      while [[ -z "$ai_technique" ]]; do
        print_prompt "Enter choice (1-6):"
        read -r choice
        case "$choice" in
          1) ai_technique="MCP" ;;
          2) ai_technique="Prompting" ;;
          3) ai_technique="Chain Of Prompt MCP" ;;
          4) ai_technique="Chains of prompt" ;;
          5) ai_technique="Mixed" ;;
          6) print_prompt "Please specify the technique:"; read -r ai_technique ;;
          *) print_warning "Invalid choice" ;;
        esac
      done

      print_prompt "Enter manager notes (max 10000 chars, press Ctrl+D when done):"
      manager_note=$(cat)
      manager_note=${manager_note:0:10000}

      print_prompt "Enter creator's role (max 5000 chars):"
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
    print_success "Configuration saved to: $output_file"
    if [[ -s "$output_file" ]]; then
      print_info "File size: $(wc -c < "$output_file") bytes"
      return 0
    fi
    print_error "File was created but is empty"
    return 1
  fi

  print_error "Failed to create valid JSON"
  [[ -f "$TEMP_DIR/jq_error.log" ]] && { print_error "JQ error:"; cat "$TEMP_DIR/jq_error.log" >&2; }
  return 1
}

#-------------------------------------------------------------------------------
# APPLY MODE
#-------------------------------------------------------------------------------
apply_license() {
  local config_file="$1"
  local recursive="${2:-true}"
  local target_dir="${3:-.}"

  if [[ ! -f "$config_file" ]]; then
    print_error "Configuration file not found: $config_file"
    return 1
  fi
  if ! jq empty "$config_file" 2>/dev/null; then
    print_error "Invalid JSON in config file: $config_file"
    return 1
  fi

  local files_ext_targeted
  files_ext_targeted=$(jq -r '.files_ext_targeted // empty' "$config_file")
  if [[ -z "$files_ext_targeted" ]]; then
    print_error "No target extensions specified in config (files_ext_targeted)"
    return 1
  fi

  local advanced_mode="false"
  local ai_used creator_role
  ai_used=$(jq -r '.ai_used // "false"' "$config_file")
  creator_role=$(jq -r '.creator_role // empty' "$config_file")
  if [[ "$ai_used" == "true" && -n "$creator_role" ]]; then
    advanced_mode="true"
    print_info "Advanced mode detected - AI role will be included in license headers"
  fi

  print_info "Applying license from $config_file"
  print_info "Target extensions: $files_ext_targeted"
  print_info "Directory: $target_dir (Recursive: $recursive)"

  IFS=',' read -ra EXTENSIONS <<< "$files_ext_targeted"
  local total_count=0

  for ext in "${EXTENSIONS[@]}"; do
    ext=$(echo "$ext" | xargs)
    [[ -z "$ext" ]] && continue

    print_info "Processing *.$ext files..."
    local license_content
    license_content=$(generate_license_text "$config_file" "text" "$advanced_mode") || continue

    local comment_style formatted_header
    comment_style=$(get_comment_style "$ext")
    formatted_header=$(format_comment_block "$comment_style" "$license_content")

    local find_args=("$target_dir" "-type" "f" "-name" "*.$ext")
    [[ "$recursive" != "true" ]] && find_args=("$target_dir" "-maxdepth" "1" "-type" "f" "-name" "*.$ext")

    local count=0
    while IFS= read -r -d '' file; do
      if head -n 5 "$file" 2>/dev/null | grep -q "LICENSE INFORMATION"; then
        print_warning "Skipping (already has license): $file"
        continue
      fi

      local temp_file="$TEMP_DIR/$(basename "$file").tmp"
      {
        echo "$formatted_header"
        echo ""
        cat "$file"
      } > "$temp_file"

      if mv "$temp_file" "$file"; then
        print_success "Licensed: $file"
        ((count++))
        ((total_count++))
      else
        print_error "Failed: $file"
      fi
    done < <(find "${find_args[@]}" -print0 2>/dev/null)

    print_success "Processed $count *.$ext files"
  done

  print_success "Total files processed: $total_count"
}

#-------------------------------------------------------------------------------
# PDF REPORT GENERATION (unchanged logic; kept from your version)
#-------------------------------------------------------------------------------
generate_latex_report() {
  local config_file="$1"
  local output_file="$2"
  local pdf_only="${3:-false}"

  if [[ ! -f "$config_file" ]]; then
    print_error "Configuration file not found: $config_file"
    return 1
  fi
  if ! jq empty "$config_file" 2>/dev/null; then
    print_error "Invalid JSON in config file: $config_file"
    return 1
  fi

  print_info "Generating report from $config_file..."

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

  author=$(jq -r '.author // .authors // "Unknown"' "$config_file")
  license_type=$(jq -r '.license_type // .["license type"] // "Unspecified"' "$config_file")
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
  full_license_text=$(jq -r '.license_text // .["licence text"] // "No license text provided."' "$config_file")

  case "$ai_used" in
    'true') ai_used="Yes" ;;
    'false') ai_used="No" ;;
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
\\rhead{License Report}
\\lhead{LHF v$VERSION}
\\rfoot{Page \\thepage}
\\title{\\textbf{License Documentation Report}\\\\\\Large Generated by LHF v$VERSION}
\\author{Deontological Framework}
\\date{\\today}
\\begin{document}
\\maketitle

\\section{License Overview}
\\begin{table}[h]
\\centering
\\renewcommand{\\arraystretch}{1.3}
\\begin{tabular}{@{}>{\\bfseries}l p{10cm}@{}}
\\toprule
Field & Value \\\\
\\midrule
Author(s) & $author \\\\
License Type & $license_type \\\\
Copyright & $copyright $year $author \\\\
Date Issued & $date_issued \\\\
License Link & \\url{$license_link} \\\\
Year of Licensing & $year \\\\
Target Files & $files_ext_targeted \\\\
\\bottomrule
\\end{tabular}
\\caption{Primary License Information}
\\end{table}

\\subsection{Copyright Notice}
The copyright symbol $copyright indicates that $author retains the intellectual property rights for the year $year.
EOF

  if [[ "$fingerprint_hash" != "N/A" ]]; then
    cat >> "$tex_file" << EOF

\\section{System Fingerprint}
This document was generated with a unique system identifier for traceability purposes.
\\begin{table}[h]
\\centering
\\renewcommand{\\arraystretch}{1.3}
\\begin{tabular}{@{}>{\\bfseries}l p{10cm}@{}}
\\toprule
Property & Value \\\\
\\midrule
Fingerprint Hash & \\texttt{$fingerprint_hash} \\\\
Generated At & $fp_timestamp \\\\
Hostname & $fp_hostname \\\\
\\bottomrule
\\end{tabular}
\\caption{System Identification}
\\end{table}
EOF
  fi

  if [[ "$ai_used" != "N/A" ]]; then
    cat >> "$tex_file" << EOF

\\section{AI Section}
\\begin{table}[h]
\\centering
\\renewcommand{\\arraystretch}{1.3}
\\begin{tabular}{@{}>{\\bfseries}l p{10cm}@{}}
\\toprule
Aspect & Details \\\\
\\midrule
AI Utilized & $ai_used \\\\
EOF

    if [[ "$ai_used" == "Yes" && "$ai_technique" != "N/A" ]]; then
      cat >> "$tex_file" << EOF
AI Technique & $ai_technique \\\\
EOF
    fi

    cat >> "$tex_file" << EOF
\\bottomrule
\\end{tabular}
\\caption{AI Usage Information}
\\end{table}
EOF

    if [[ "$ai_used" == "Yes" && "$ai_technique" != "N/A" ]]; then
      cat >> "$tex_file" << EOF

\\subsection{Technical Approach}
The development of this work employed \\textbf{$ai_technique} as the primary AI programming methodology.
EOF
    fi
  fi

  if [[ "$creator_role" != "N/A" && -n "$creator_role" ]]; then
    cat >> "$tex_file" << EOF

\\section{Personnel and Responsibilities}
\\subsection{Creator's Role}
\\begin{quote}
$creator_role
\\end{quote}
EOF
  fi

  if [[ "$manager_note" != "N/A" && -n "$manager_note" ]]; then
    cat >> "$tex_file" << EOF

\\section{Administrative Notes}
\\subsection{Managerial Observations}
\\begin{quote}
$manager_note
\\end{quote}
EOF
  fi

  if [[ -n "$logo" && "$logo" != "null" && "$logo" != "N/A" ]]; then
    cat >> "$tex_file" << EOF

\\section{Visual Identity}
\\begin{center}
\\url{$logo}
\\end{center}
EOF
  fi

  cat >> "$tex_file" << 'LATEX_LEGAL'
\section{Legal Text}
\begin{center}
\textit{The complete legal text of the license is provided below:}
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
\\textit{This report was automatically generated by the License Header Framework v$VERSION}\\\\
\\textit{Document Version: $DEONT_VERSION | Generation Date: \\today}\\\\
System Fingerprint: \\texttt{$fingerprint_hash}
\\end{center}
\\end{document}
EOF

  print_success "LaTeX source generated: $tex_file"

  if command -v pdflatex &> /dev/null; then
    print_info "Compiling PDF..."
    local tex_dir tex_name
    tex_dir=$(dirname "$tex_file")
    tex_name=$(basename "$tex_file")
    (cd "$tex_dir" && pdflatex -interaction=nonstopmode "$tex_name" > /dev/null 2>&1)
    (cd "$tex_dir" && pdflatex -interaction=nonstopmode "$tex_name" > /dev/null 2>&1)

    if [[ -f "$pdf_file" ]]; then
      print_success "PDF generated: $pdf_file"
      rm -f "${tex_file%.tex}.aux" "${tex_file%.tex}.log" "${tex_file%.tex}.out"
      [[ "$pdf_only" == "true" ]] && rm -f "$tex_file"
      return 0
    fi

    print_error "PDF compilation failed"
    return 1
  fi

  print_warning "pdflatex not found. Install texlive-full to generate PDF."
  print_info "LaTeX source saved: $tex_file"
  return 1
}

#-------------------------------------------------------------------------------
# HELP
#-------------------------------------------------------------------------------
show_help() {
  cat << EOF
License Header Framework (LHF) v$VERSION

USAGE:
./$SCRIPT_NAME [COMMAND] [OPTIONS]

COMMANDS:
  init       Initialize configuration directory
  create     Create .deont file (interactive by default)
  apply      Apply license headers to files using .deont
  report     Generate PDF report from .deont
  validate   Validate .deont file

OPTIONS:
  -f, --file FILE         .deont file path (default: ./.deont)
  -a, --author NAME       Author name (for quick create)
  -l, --license TYPE      License type (MIT, GPL, etc.)
  -t, --text TEXT         License text (or @file.txt)
  -d, --date DATE         Date issued (YYYY-MM-DD)
  -y, --year YEAR         License year
  -u, --url URL           License URL
  -e, --extensions EXT    Target extensions (comma-separated)
  -r, --recursive         Recursive mode for apply
  --dir DIRECTORY         Target directory (default: .)
  --advanced              Enable advanced fields (AI, fingerprint)
  --pdf-only              Generate only PDF
  -h, --help              Show help
  -v, --version           Show version

EXAMPLES:
  ./$SCRIPT_NAME create --advanced
  ./$SCRIPT_NAME apply -f .deont -r --dir ./src
  ./$SCRIPT_NAME report -f .deont --pdf-only
EOF
}

#-------------------------------------------------------------------------------
# MAIN
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
      *) print_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  case "$command" in
    'init')
      mkdir -p "$DEFAULT_CONFIG_DIR" "$TEMPLATES_DIR"
      print_success "Initialized LHF at $DEFAULT_CONFIG_DIR"
      ;;
    'create')
      if [[ -n "$author" && -n "$license_type" && -n "$license_text" && -n "$year" && -n "$extensions" ]]; then
        print_info "Quick creating .deont file: $deont_file"

        if [[ "$license_text" == @* ]]; then
          local text_file="${license_text#@}"
          if [[ -f "$text_file" ]]; then
            license_text=$(cat "$text_file")
          else
            print_error "License text file not found: $text_file"
            exit 1
          fi
        fi

        [[ -z "$date_issued" ]] && date_issued=$(date +%Y-%m-%d)
        [[ -z "$license_link" ]] && license_link="https://opensource.org/licenses/$license_type"
        [[ -z "$logo" ]] && logo=""

        local fingerprint_json
        fingerprint_json=$(generate_system_fingerprint)
        if [[ -z "$fingerprint_json" ]] || ! echo "$fingerprint_json" | jq empty >/dev/null 2>&1; then
          print_error "Failed to generate valid fingerprint"
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
          print_success "Created: $deont_file"
        else
          print_error "Failed to create .deont file"
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
        print_success ".deont file is valid: $deont_file"
      else
        print_error "Validation failed for: $deont_file"
        exit 1
      fi
      ;;
    '')
      print_banner
      show_help
      ;;
    *)
      print_error "Unknown command: $command"
      exit 1
      ;;
  esac
}

main "$@"
