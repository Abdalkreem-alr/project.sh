#!/bin/bash

# ألوان للإخراج
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
    echo -e "${GREEN}Usage: $0 [-r domain] [-n target] [-v target] [-a target]${NC}"
    echo "  -r domain    Run Recon (Subdomain Enumeration)"
    echo "  -w domain    scan endpoin"
    echo "  -n target    Scan for open ports and running services"
    echo "  -v target    Search for known vulnerabilities"
    echo "  -l domain    Filter live domains using httpx"
    echo "  -a target    Run all: Recon + Services + Vulnerabilities"
    exit 1
}

# دالة لجمع Subdomains
recon() {
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
    echo -e "${GREEN}[+] Done! Results saved to subdomains.txt${NC}"

    # حذف المؤقتات
    rm -f "$output_dir/subfinder.txt" "$output_dir/crt.txt"
}

filter_live_domains() {
    domain=$1
    input_file=~/recon/$domain/subdomain/subdomains.txt
    output_file=~/recon/$domain/subdomain/live.txt

    echo -e "${GREEN}[+] Filtering live domains for $domain using httpx...${NC}"

    if ! command -v httpx &>/dev/null; then
        echo -e "${RED}[-] httpx not found. Please install it.${NC}"
        return 1
    fi

    if [[ ! -s "$input_file" ]]; then
        echo -e "${RED}[-] Subdomains file is missing or empty: $input_file${NC}"
        return 1
    fi

    httpx1 -silent -l "$input_file" -o "$output_file"

    echo -e "${GREEN}[+] Live domains saved to $output_file${NC}"
}
gather_endpoints() {
    domain=$1
    echo -e "${GREEN}[+] Gathering endpoints for $domain using waybackurls...${NC}"

    # تحقق من وجود الأداة
    if ! command -v waybackurls &>/dev/null; then
        echo -e "${RED}[-] waybackurls not found. Please install it.${NC}"
        return 1
    fi

    subdomains_file=~/recon/$domain/subdomain/subdomains.txt
    output_dir=~/recon/$domain/endpoint
    output_file="$output_dir/waybackurls.txt"
    mkdir -p "$output_dir"

    # تحقق من وجود ملف subdomains
    if [[ ! -s "$subdomains_file" ]]; then
        echo -e "${RED}[-] Subdomains file not found or empty: $subdomains_file${NC}"
        return 1
    fi

    echo -e "${GREEN}[*] Fetching URLs from $(wc -l < "$subdomains_file") subdomains...${NC}"
    
    # تنفيذ waybackurls بشكل أسرع
    cat "$subdomains_file" | waybackurls | sort -u > "$output_file"

    echo -e "${GREEN}[+] Done. Saved to $output_file${NC}"
}



# دالة لفحص الخدمات
scan_services() {
    target=$1
    echo -e "${GREEN}[+] Scanning $target for open ports and services...${NC}"
    nmap -sV "$target"
}

# دالة للثغرات
find_vulnerabilities() {
    target=$1
    echo -e "${GREEN}[+] Scanning $target for known vulnerabilities...${NC}"
    nmap -sV --script vuln "$target"
}

# التحقق من المعطيات
if [[ $# -lt 2 ]]; then
    usage
fi

while getopts ":r:n:v:a:w:l:" opt; do
    case $opt in
        r)
            recon "$OPTARG"
            ;;
        l)
            filter_live_domains "$OPTARG"
            ;;
        n)
            scan_services "$OPTARG"
            ;;
        v)
            find_vulnerabilities "$OPTARG"       
            ;;

        w)
            gather_endpoints "$OPTARG"
             ;;
        a)
            domain="$OPTARG"
            ip=$(dig +short "$domain" | tail -n1)
            echo -e "${GREEN}[*] Domain: $domain => IP: $ip${NC}"
            recon "$domain"
            scan_services "$ip"
            find_vulnerabilities "$ip"
            gather_endpoints "$domain"
            ;;
        *)
            usage
            ;;
    esac
done
