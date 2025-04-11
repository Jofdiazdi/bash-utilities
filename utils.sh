check_dependencies() {
    local deps=("$@")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo "❌ Missing dependencies: ${missing[*]}"
        echo ""

        # Detect distro and suggest install command
        if [ -f /etc/arch-release ]; then
            echo "📦 You can install them with:"
            echo "    sudo pacman -S --needed ${missing[*]}"
        elif [ -f /etc/debian_version ]; then
            echo "📦 You can install them with:"
            echo "    sudo apt update && sudo apt install ${missing[*]}"
        else
            echo "⚠️ Unknown distro. Please install the above packages manually."
        fi

        exit 1
    fi
}
