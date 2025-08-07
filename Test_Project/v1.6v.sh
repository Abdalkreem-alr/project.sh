#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

print_banner() {
    echo -e "${GREEN}"
    echo "██████╗   ██████╗      ██████╗        ██╗    ███████╗  ██████╗  ████████╗"
    echo "██╔══██╗ ██╔   ██║    ██╔═══██╗       ██║    ██╔════╝ ██╔════╝  ╚══██╔══╝"
    echo "██████╔╝ ██╔██╔██║    ██║   ██║       ██║    █████╗   ██║          ██║   "
    echo "██╔═══╝  ██╔   ██║    ██║   ██║       ██║    ██╔══╝   ██║          ██║   "
    echo "██║      ██╔    ██║   ╚██████╔╝║██    ██║    ███████╗ ╚██████╗     ██║   "
    echo "╚═╝      ╚════════╝             ╚█████╔╝     ╚══════╝  ╚═════╝     ╚═╝   "
    echo -e "${NC}"
    echo -e "${GREEN}Cyber Recon Toolkit by Abdulkarim Ramzi, Khaled Jaradeh, Rami Safi, Hasan Alqudra${NC}\n"
}

print_banner


usage() {
    echo -e "${GREEN}Usage: $0 [-r domain] [-n domain]  [-l domain] [-w domain] [-d domain] ${NC}"
    echo "  -r domain    Run subdomain Enumeration"
    echo "  -w domain    scan endpoint"
    echo "  -l domain    Filter live domains using httpx"
    echo "  -n domain    Scan for open ports "
    echo "  -d domain    Get DNS A, CNAME, and TXT records"
    exit 1
}


subdomain_enum() {
    domain=$1
    echo -e "${GREEN}[+] Running Subdomain Enumeration on $domain using subfinder and crt.sh...${NC}"

    # التحقق من الأدوات
    output_dir=~/recon/$domain/subdomain
    mkdir -p "$output_dir"

    if ! command -v subfinder &>/dev/null; then
        echo -e "${RED}[-] subfinder not found. Please install it.${NC}"
        return
    fi

    if ! command -v jq &>/dev/null; then
        echo -e "${RED}[-] jq not found. Please install it.${NC}"
        return
    fi

    # تنفيذ subfinder
    echo "[*] Using subfinder..."
    subfinder -d "$domain" --silent -o "$output_dir/subfinder.txt"

    # تنفيذ crt.sh
    echo "[*] Using crt.sh..."
    curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sort -u > "$output_dir/crt.txt"

    # دمج النتائج
    echo "[*] Merging and deduplicating results..."
    cat "$output_dir/subfinder.txt" "$output_dir/crt.txt" | sort -u > "$output_dir/subdomains.txt"
    echo -e "${GREEN}[+] Done! Results saved to $output_dir/subdomains.txt${NC}"

    # حذف المؤقتات
    rm -f "$output_dir/subfinder.txt" "$output_dir/crt.txt"
}


filter_live_domains() {
    domain=$1
    input_file=~/recon/$domain/subdomain/subdomains.txt
    output_file=~/recon/$domain/subdomain/live.txt

    echo -e "${GREEN}[+] Filtering live domains for: $domain${NC}"

    if ! command -v httpx &>/dev/null; then
        echo -e "${RED}[-] httpx not found. Please install it.${NC}"
        return 1
    fi

    if [[ ! -f "$input_file" || ! -s "$input_file" ]]; then
        echo -e "${YELLOW}[!] Subdomains file missing or empty.${NC}"
        read -p "❓ Do you want to run subdomain_enum now? (y/n): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            subdomain_enum "$domain"
        else
            echo -e "${RED}[-] Operation cancelled. Please run '-r' first.${NC}"
            return 1
        fi
    fi

    if [[ ! -s "$input_file" ]]; then
        echo -e "${RED}[-] Still no subdomains found. Aborting.${NC}"
        return 1
    fi

    httpx -silent -l "$input_file" -o "$output_file"

    count=$(wc -l < "$output_file")
    echo -e "${GREEN}[+] Found $count live domains. Results saved to $output_file${NC}"
}


gather_endpoints() {
    domain=$1
    echo -e "${GREEN}[+] Gathering endpoints for $domain using waybackurls and gau...${NC}"

    
    if ! command -v waybackurls &>/dev/null; then
        echo -e "${RED}[-] waybackurls not found. Please install it.${NC}"
        return 1
    fi

    subdomains_file=~/recon/$domain/subdomain/subdomains.txt
    output_dir=~/recon/$domain/endpoint
    output_file="$output_dir/waybackurls.txt"
    mkdir -p "$output_dir"


     if [[ ! -f "$subdomains_file" || ! -s "$subdomains_file" ]]; then
        echo -e "${YELLOW}[!] Subdomains file missing or empty for $domain.${NC}"
        read -p "❓ Do you want to run subdomain_enum now? (y/n): " confirm
        if [[ $confirm == "y" || $confirm == "Y" ]]; then
            subdomain_enum "$domain"
        else
            echo -e "${RED}[-] Operation cancelled. Please run '-r' first to collect subdomains.${NC}"
            return 1
        fi
    fi


    if [[ ! -s "$subdomains_file" ]]; then
        echo -e "${RED}[-] Still no subdomains found after running subdomain_enum. Aborting.${NC}"
        return 1
    fi

    echo -e "${GREEN}[*] Fetching URLs from $(wc -l < "$subdomains_file") subdomains...${NC}"
    cat "$subdomains_file" | waybackurls > "$output_file"

    
    if command -v gau &>/dev/null; then
        cat "$subdomains_file" | gau --threads 50 >> "$output_file"
        sort -u "$output_file" -o "$output_file"
        echo -e "${GREEN}[+] Merged with gau results.${NC}"
    fi

    
    grep -vE '\.(jpg|jpeg|png|gif|svg|css|woff|woff2|ttf|eot|ico)$' "$output_file" | sort -u > "$output_dir/filtered.txt"

    
    grep '\.js' "$output_file" > "$output_dir/js.txt"
    grep '\.php' "$output_file" > "$output_dir/php.txt"
    grep '\.aspx\|\.asp' "$output_file" > "$output_dir/aspx.txt"
    grep -E '\.json|\.xml' "$output_file" > "$output_dir/api.txt"

    
    cat "$output_file" | grep '?' | cut -d '?' -f2 | cut -d '&' -f1 | cut -d '=' -f1 | sort -u > "$output_dir/parameters.txt"

    
    count=$(wc -l < "$output_file")
    filtered=$(wc -l < "$output_dir/filtered.txt")
    echo -e "${GREEN}[+] Total endpoints: $count | Filtered: $filtered${NC}"
    echo -e "${GREEN}[+] Saved to $output_dir${NC}"
}



scan_services() {
    full_subdomain=$1
    safe_name=$(echo "$full_subdomain" | sed 's/\./_/g')
    output_dir=~/recon/scan/$safe_name
    output_file="$output_dir/naabu.txt"

    mkdir -p "$output_dir"

    echo -e "${GREEN}[+] Scanning open ports on $full_subdomain using Naabu...${NC}"

    if ! command -v naabu &>/dev/null; then
        echo -e "${RED}[-] naabu not found. Please install it.${NC}"
        return 1
    fi

    naabu -host "$full_subdomain" -silent -o "$output_file"

    if [[ ! -s "$output_file" ]]; then
        echo -e "${RED}[-] No open ports found on $full_subdomain.${NC}"
    else
        echo -e "${GREEN}[+] Naabu scan completed. Results saved to $output_file${NC}"
        echo -e "${GREEN}[+] Open ports on $full_subdomain:${NC}"
        cat "$output_file"
    fi
}





dns_records() {
    subdomain=$1
    safe_name=$(echo "$subdomain" | sed 's/\./_/g')
    output_dir=~/recon/dns-records/$safe_name
    output_file="$output_dir/dns.txt"

    mkdir -p "$output_dir"

    echo -e "${GREEN}[+] Gathering DNS records for $subdomain ...${NC}"

    {
        echo "=== A Record ==="
        dig +short A "$subdomain"

        echo -e "\n=== CNAME Record ==="
        dig +short CNAME "$subdomain"

        echo -e "\n=== TXT Record ==="
        dig +short TXT "$subdomain"
    } > "$output_file"

    echo -e "${GREEN}[+] Results saved to $output_file${NC}"
}




if [[ $# -lt 2 ]]; then
    usage
fi

while getopts ":r:n:w:l:d:" opt; do
    case $opt in
        r)
            subdomain_enum "$OPTARG"
            ;;
        l)
            filter_live_domains "$OPTARG"
            ;;
        n)
            scan_services "$OPTARG"
            ;;

        w)
            gather_endpoints "$OPTARG"
             ;;
        d)
            dns_records "$OPTARG"
            ;;
      
        *)
            usage
            ;;
    esac
done
