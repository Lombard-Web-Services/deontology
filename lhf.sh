
        
        echo
        print_prompt "Enter manager notes (max 10000 chars, press Ctrl+D when done):"
        local manager_note
        manager_note=$(cat)
        manager_note=${manager_note:0:10000}
        manager_note=$(echo "$manager_note" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')
        json_data+=",\"manager_note\":\"$manager_note\""
        
        echo
        print_prompt "Enter creator's role (max 5000 chars):"
        local creator_role
        read -r creator_role
        creator_role=${creator_role:0:5000}
        creator_role=$(echo "$creator_role" | sed 's/\\/\\\\/g; s/"/\\"/g')
        json_data+=",\"creator_role\":\"$creator_role\""
    fi
    
    json_data+="}"
    
    # Write to .deont file
    if echo "$json_data" | jq '.' > "$output_file" 2>/dev/null; then
        print_success "Configuration saved to: $output_file"
        return 0
    else
        print_error "Failed to create valid JSON"
        return 1
    fi
}

#-------------------------------------------------------------------------------
# APPLY MODE - Apply license headers using .deont file
#-------------------------------------------------------------------------------

apply_license() {
    local config_file="$1"
    local extension="$2"
    local recursive="${3:-true}"
    local target_dir="${4:-.}"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
        return 1
    fi
    
    print_info "Applying license from $config_file to *.$extension files"
    print_info "Directory: $target_dir (Recursive: $recursive)"
    
    local license_content
    license_content=$(generate_license_text "$config_file" "text") || return 1
    
    local comment_style
    comment_style=$(get_comment_style "$extension")
    
    local formatted_header
    formatted_header=$(format_comment_block "$comment_style" "$license_content")
    
    local find_args=("$target_dir" "-type" "f" "-name" "*.$extension")
    [[ "$recursive" != "true" ]] && find_args=("$target_dir" "-maxdepth" "1" "-type" "f" "-name" "*.$extension")
    
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
        else
            print_error "Failed: $file"
        fi
        
    done < <(find "${find_args[@]}" -print0 2>/dev/null)
    
    print_success "Processed $count files"
}

#-------------------------------------------------------------------------------
# REPORT GENERATION
#-------------------------------------------------------------------------------

generate_latex_report() {
    local config_file="$1"
    local output_file="$2"
    local pdf_only="${3:-false}"
    
    if [[ ! -f "$config_file" ]]; then
        print_error "Configuration file not found: $config_file"
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
    
    # Extract data
    local author license_type copyright date_issued license_link year logo
    local ai_used ai_technique manager_note creator_role
    
    author=$(jq -r '.author // .authors // "Unknown"' "$config_file")
    license_type=$(jq -r '.license_type // .["license type"] // "Unspecified"' "$config_file")
    copyright=$(jq -r '.copyright_signs // .["copyright signs"] // "©"' "$config_file")
    date_issued=$(jq -r '.date_license_issued // .["date license issued"] // "N/A"' "$config_file")
    license_link=$(jq -r '.license_link // .["license link"] // "N/A"' "$config_file")
    year=$(jq -r '.year_of_licensing // .["year of licensing"] // "N/A"' "$config_file")
    logo=$(jq -r '.logo // empty' "$config_file")
    
    ai_used=$(jq -r '.ai_used // "N/A"' "$config_file")
    ai_technique=$(jq -r '.ai_technique // "N/A"' "$config_file")
    manager_note=$(jq -r '.manager_note // "N/A"' "$config_file")
    creator_role=$(jq -r '.creator_role // "N/A"' "$config_file")
    
    case "$ai_used" in
        'true') ai_used="Yes" ;;
        'false') ai_used="No" ;;
    esac
    
    # Escape LaTeX
    author=$(echo "$author" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g; s/{/\\{/g; s/}/\\}/g; s/~/$\\sim$/g; s/\^/\\^/g')
    license_type=$(echo "$license_type" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g; s/{/\\{/g; s/}/\\}/g')
    
    cat > "$tex_file" << EOF
\\documentclass[12pt,a4paper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{geometry}
\\usepackage{booktabs}
\\usepackage{hyperref}
\\usepackage{fancyhdr}
\\usepackage{array}
\\geometry{margin=2.5cm}
\\pagestyle{fancy}
\\fancyhf{}
\\rhead{License Report}
\\lhead{${author:0:50}}
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
\\bottomrule
\\end{tabular}
\\caption{License Information}
\\end{table}
\\subsection{Copyright Notice}
The copyright symbol $copyright indicates that $author retains the intellectual property rights for the year $year.
EOF

    if [[ -n "$logo" && "$logo" != "null" && "$logo" != "N/A" ]]; then
        cat >> "$tex_file" << EOF
\\subsection{Visual Identity}
\\begin{center}
\\url{$logo}
\\end{center}
EOF
    fi

    if [[ "$ai_used" != "N/A" ]]; then
        cat >> "$tex_file" << EOF
\\section{AI Disclosure}
\\begin{tabular}{@{}>{\\bfseries}l p{10cm}@{}}
AI Utilized & $ai_used \\\\
EOF
        [[ "$ai_used" == "Yes" && "$ai_technique" != "N/A" ]] && cat >> "$tex_file" << EOF
AI Technique & $ai_technique \\\\
EOF
        cat >> "$tex_file" << EOF
\\end{tabular}
EOF
    fi

    if [[ "$creator_role" != "N/A" && -n "$creator_role" ]]; then
        creator_role=$(echo "$creator_role" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g')
        cat >> "$tex_file" << EOF
\\section{Creator's Role}
\\begin{quote}
$creator_role
\\end{quote}
EOF
    fi

    if [[ "$manager_note" != "N/A" && -n "$manager_note" ]]; then
        manager_note=$(echo "$manager_note" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g')
        cat >> "$tex_file" << EOF
\\section{Manager Notes}
\\begin{quote}
$manager_note
\\end{quote}
EOF
    fi

    local full_license_text
    full_license_text=$(jq -r '.license_text // .["licence text"] // "No license text provided."' "$config_file" | sed 's/\\/\\\\/g; s/&/\\&/g; s/%/\\%/g; s/\$/\\$/g; s/#/\\#/g; s/_/\\_/g; s/{/\\{/g; s/}/\\}/g')
    
    cat >> "$tex_file" << EOF
\\section{Legal Text}
\\begin{verbatim}
$full_license_text
\\end{verbatim}
\\vfill
\\begin{center}
\\textit{Generated by LHF v$VERSION | $(date '+%Y-%m-%d %H:%M:%S')}
\\end{center}
\\end{document}
EOF

    if command -v pdflatex &> /dev/null; then
        print_info "Compiling PDF..."
        local tex_dir
        tex_dir=$(dirname "$tex_file")
        local tex_name
        tex_name=$(basename "$tex_file")
        
        (cd "$tex_dir" && pdflatex -interaction=nonstopmode "$tex_name" > /dev/null 2>&1)
        (cd "$tex_dir" && pdflatex -interaction=nonstopmode "$tex_name" > /dev/null 2>&1)
        
        if [[ -f "$pdf_file" ]]; then
            print_success "PDF generated: $pdf_file"
            rm -f "${tex_file%.tex}.aux" "${tex_file%.tex}.log" "${tex_file%.tex}.out"
            [[ "$pdf_only" == "true" ]] && rm -f "$tex_file"
            return 0
        fi
    fi
    
    print_warning "PDF compilation failed or pdflatex not found"
    print_info "LaTeX source saved: $tex_file"
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
    init                    Initialize configuration directory
    create                  Create .deont file (interactive by default)
    apply                   Apply license headers to files using .deont
    report                  Generate PDF report from .deont
    validate                Validate .deont file

OPTIONS:
    -f, --file FILE         .deont file path (default: ./.deont)
    -a, --author NAME       Author name (for quick create)
    -l, --license TYPE      License type (MIT, GPL, etc.)
    -t, --text TEXT         License text (or @file.txt)
    -d, --date DATE         Date issued (YYYY-MM-DD)
    -y, --year YEAR         License year
    -u, --url URL           License URL
    -e, --extension EXT     Target file extension for apply
    -r, --recursive         Recursive mode for apply
    --dir DIRECTORY         Target directory (default: .)
    --advanced              Enable advanced fields
    --pdf-only              Generate only PDF
    -h, --help              Show help
    -v, --version           Show version

EXAMPLES:
    # Interactive creation
    ./$SCRIPT_NAME create
    ./$SCRIPT_NAME create --advanced -f ./config.deont
    
    # Quick creation
    ./$SCRIPT_NAME create -a "John Doe" -l "MIT" -t "@license.txt" -y 2024
    
    # Apply to files
    ./$SCRIPT_NAME apply -f .deont -e js -r --dir ./src
    
    # Generate report
    ./$SCRIPT_NAME report -f .deont --pdf-only

EOF
}

#-------------------------------------------------------------------------------
# MAIN - UNIFIED COMMAND STRUCTURE
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
    local extension=""
    local recursive="false"
    local target_dir="."
    local advanced="false"
    local pdf_only="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            init|create|apply|report|validate)
                command="$1"
                shift 1
                ;;
            -f|--file)
                deont_file="$2"
                shift 2
                ;;
            -a|--author)
                author="$2"
                shift 2
                ;;
            -l|--license)
                license_type="$2"
                shift 2
                ;;
            -t|--text)
                license_text="$2"
                shift 2
                ;;
            -d|--date)
                date_issued="$2"
                shift 2
                ;;
            -u|--url)
                license_link="$2"
                shift 2
                ;;
            -y|--year)
                year="$2"
                shift 2
                ;;
            --logo)
                logo="$2"
                shift 2
                ;;
            -e|--extension)
                extension="$2"
                shift 2
                ;;
            -r|--recursive)
                recursive="true"
                shift 1
                ;;
            --dir)
                target_dir="$2"
                shift 2
                ;;
            --advanced)
                advanced="true"
                shift 1
                ;;
            --pdf-only)
                pdf_only="true"
                shift 1
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "$SCRIPT_NAME version $VERSION"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        'init')
            mkdir -p "$DEFAULT_CONFIG_DIR" "$TEMPLATES_DIR"
            print_success "Initialized LHF at $DEFAULT_CONFIG_DIR"
            ;;
            
        'create')
            # Check if quick creation or interactive
            if [[ -n "$author" && -n "$license_type" && -n "$license_text" && -n "$year" ]]; then
                # Quick command-line creation
                print_info "Quick creating .deont file: $deont_file"
                
                # Handle @file.txt syntax for license text
                if [[ "$license_text" == @* ]]; then
                    local text_file="${license_text#@}"
                    if [[ -f "$text_file" ]]; then
                        license_text=$(cat "$text_file")
                    else
                        print_error "License text file not found: $text_file"
                        exit 1
                    fi
                fi
                
                # Auto-fill defaults
                [[ -z "$date_issued" ]] && date_issued=$(date +%Y-%m-%d)
                [[ -z "$license_link" ]] && license_link="https://opensource.org/licenses/$license_type"
                [[ -z "$logo" ]] && logo=""
                
                # Build JSON
                jq -n \
                    --arg author "$author" \
                    --arg license_type "$license_type" \
                    --arg license_text "$license_text" \
                    --arg copyright "©" \
                    --arg date_issued "$date_issued" \
                    --arg license_link "$license_link" \
                    --arg year "$year" \
                    --arg logo "$logo" \
                    '{
                        author: $author,
                        license_type: $license_type,
                        license_text: $license_text,
                        copyright_signs: $copyright,
                        date_license_issued: $date_issued,
                        license_link: $license_link,
                        year_of_licensing: $year,
                        logo: $logo
                    }' > "$deont_file"
                
                if [[ $? -eq 0 ]]; then
                    print_success "Created: $deont_file"
                else
                    print_error "Failed to create .deont file"
                    exit 1
                fi
            else
                # Interactive mode
                interactive_mode "$deont_file" "$advanced"
            fi
            ;;
            
        'apply')
            if [[ -z "$extension" ]]; then
                print_error "Apply command requires --extension"
                exit 1
            fi
            apply_license "$deont_file" "$extension" "$recursive" "$target_dir"
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
            
