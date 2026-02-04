#!/bin/bash
# ==============================================================================
# xdns Unit Tests
# ==============================================================================
# Usage: ./test_xdns.sh
# Requires: Running as user (not root) for safety
# ==============================================================================

set -uo pipefail

# --- Test Configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly XDNS_SCRIPT="$SCRIPT_DIR/xdns"

# --- Colors ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# --- Counters ---
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ==============================================================================
# TEST FRAMEWORK
# ==============================================================================

log_test() {
    echo -e "${CYAN}[TEST]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
    ((TESTS_FAILED++))
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    if [[ "$expected" == "$actual" ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_true() {
    local condition="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    if eval "$condition"; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local test_name="$2"
    
    ((TESTS_RUN++))
    if ! eval "$condition"; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    ((TESTS_RUN++))
    if [[ "$expected" -eq "$actual" ]]; then
        log_pass "$test_name"
        return 0
    else
        log_fail "$test_name (expected exit: $expected, got: $actual)"
        return 1
    fi
}

# ==============================================================================
# SOURCE FUNCTIONS FROM XDNS (without executing main)
# ==============================================================================

# Extract only the functions we need to test
source_functions() {
    # Create temp file with functions only
    local tmp_file
    tmp_file=$(mktemp)
    
    # Filter out readonly variable definitions to avoid conflicts during testing
    # The 'main' check is no longer needed due to the "If Sourced" guard in xdns
    grep -vE "^readonly (RED|GREEN|YELLOW|BLUE|CYAN|NC)=" "$XDNS_SCRIPT" > "$tmp_file"
    
    # Source the modified script
    # shellcheck disable=SC1090
    source "$tmp_file"
    
    rm -f "$tmp_file"
}

# ==============================================================================
# TEST: validate_ipv4
# ==============================================================================

test_validate_ipv4() {
    echo ""
    echo "========================================"
    echo "Testing: validate_ipv4()"
    echo "========================================"
    
    # Valid IPs
    validate_ipv4 "8.8.8.8"
    assert_exit_code 0 $? "Valid IP: 8.8.8.8"
    
    validate_ipv4 "1.1.1.1"
    assert_exit_code 0 $? "Valid IP: 1.1.1.1"
    
    validate_ipv4 "192.168.1.1"
    assert_exit_code 0 $? "Valid IP: 192.168.1.1"
    
    validate_ipv4 "0.0.0.0"
    assert_exit_code 0 $? "Valid IP: 0.0.0.0"
    
    validate_ipv4 "255.255.255.255"
    assert_exit_code 0 $? "Valid IP: 255.255.255.255"
    
    # Invalid IPs
    validate_ipv4 "256.1.1.1"
    assert_exit_code 1 $? "Invalid IP: 256.1.1.1 (octet > 255)"
    
    validate_ipv4 "1.1.1"
    assert_exit_code 1 $? "Invalid IP: 1.1.1 (only 3 octets)"
    
    validate_ipv4 "1.1.1.1.1"
    assert_exit_code 1 $? "Invalid IP: 1.1.1.1.1 (5 octets)"
    
    validate_ipv4 "abc.def.ghi.jkl"
    assert_exit_code 1 $? "Invalid IP: abc.def.ghi.jkl (letters)"
    
    validate_ipv4 ""
    assert_exit_code 1 $? "Invalid IP: empty string"
    
    validate_ipv4 "8.8.8.8.8"
    assert_exit_code 1 $? "Invalid IP: 8.8.8.8.8 (too many octets)"
    
    validate_ipv4 "-1.0.0.0"
    assert_exit_code 1 $? "Invalid IP: -1.0.0.0 (negative)"
    
    validate_ipv4 "1.2.3.4a"
    assert_exit_code 1 $? "Invalid IP: 1.2.3.4a (trailing letter)"
}

# ==============================================================================
# TEST: DNS Provider Arrays
# ==============================================================================

test_dns_providers() {
    echo ""
    echo "========================================"
    echo "Testing: DNS Provider Configuration"
    echo "========================================"
    
    # Test via --list output (more reliable than sourcing arrays)
    local output
    output=$("$XDNS_SCRIPT" --list 2>&1)
    
    # Check all 7 providers appear in list
    assert_true "[[ \"$output\" == *\"Google\"* ]]" "Provider 1 exists (Google)"
    assert_true "[[ \"$output\" == *\"Cloudflare\"* ]]" "Provider 2 exists (Cloudflare)"
    assert_true "[[ \"$output\" == *\"Quad9\"* ]]" "Provider 4 exists (Quad9)"
    assert_true "[[ \"$output\" == *\"AdGuard\"* ]]" "Provider 5 exists (AdGuard)"
    assert_true "[[ \"$output\" == *\"OpenDNS\"* ]]" "Provider 6 exists (OpenDNS)"
    assert_true "[[ \"$output\" == *\"Verisign\"* ]]" "Provider 7 exists (Verisign)"
    
    # Check IPs appear in list
    assert_true "[[ \"$output\" == *\"8.8.8.8\"* ]]" "Google DNS IP shown"
    assert_true "[[ \"$output\" == *\"1.1.1.1\"* ]]" "Cloudflare DNS IP shown"
    assert_true "[[ \"$output\" == *\"9.9.9.9\"* ]]" "Quad9 DNS IP shown"
}

# ==============================================================================
# TEST: Constants
# ==============================================================================

test_constants() {
    echo ""
    echo "========================================"
    echo "Testing: Constants Definition"
    echo "========================================"
    
    assert_true "[[ -n \"$VERSION\" ]]" "VERSION is defined"
    assert_true "[[ \"$VERSION\" == \"3.3.0\" ]]" "VERSION is 3.3.0"
    
    assert_true "[[ -n \"$RESOLV_CONF\" ]]" "RESOLV_CONF is defined"
    assert_equals "/etc/resolv.conf" "$RESOLV_CONF" "RESOLV_CONF path correct"
    
    assert_true "[[ -n \"$BACKUP_DIR\" ]]" "BACKUP_DIR is defined"
    assert_equals "/var/backups/xdns" "$BACKUP_DIR" "BACKUP_DIR path correct"
    
    # Network constants
    assert_true "[[ \"$PING_COUNT\" -gt 0 ]]" "PING_COUNT is positive"
    assert_true "[[ \"$PING_TIMEOUT\" -gt 0 ]]" "PING_TIMEOUT is positive"
    assert_true "[[ \"$LATENCY_FAST\" -gt 0 ]]" "LATENCY_FAST is positive"
    assert_true "[[ \"$LATENCY_MEDIUM\" -gt \"$LATENCY_FAST\" ]]" "LATENCY_MEDIUM > LATENCY_FAST"
}

# ==============================================================================
# TEST: Exit Codes
# ==============================================================================

test_exit_codes() {
    echo ""
    echo "========================================"
    echo "Testing: Exit Codes"
    echo "========================================"
    
    assert_equals 0 "$EXIT_SUCCESS" "EXIT_SUCCESS = 0"
    assert_equals 1 "$EXIT_ERROR" "EXIT_ERROR = 1"
    assert_equals 2 "$EXIT_NOT_ROOT" "EXIT_NOT_ROOT = 2"
    assert_equals 3 "$EXIT_MISSING_DEPS" "EXIT_MISSING_DEPS = 3"
    assert_equals 4 "$EXIT_NETWORK_ERROR" "EXIT_NETWORK_ERROR = 4"
}

# ==============================================================================
# TEST: CLI Arguments (without root)
# ==============================================================================

test_cli_help() {
    echo ""
    echo "========================================"
    echo "Testing: CLI Arguments"
    echo "========================================"
    
    # Help should work without root
    local output
    output=$("$XDNS_SCRIPT" --help 2>&1)
    assert_exit_code 0 $? "--help exits with 0"
    assert_true "[[ \"$output\" == *\"USAGE\"* ]]" "--help contains USAGE"
    assert_true "[[ \"$output\" == *\"OPTIONS\"* ]]" "--help contains OPTIONS"
    
    # Version should work without root
    output=$("$XDNS_SCRIPT" --version 2>&1)
    assert_exit_code 0 $? "--version exits with 0"
    assert_true "[[ \"$output\" == *\"3.3.0\"* ]]" "--version shows 3.3.0"
    
    # List should work without root
    output=$("$XDNS_SCRIPT" --list 2>&1)
    assert_exit_code 0 $? "--list exits with 0"
    assert_true "[[ \"$output\" == *\"Google\"* ]]" "--list shows Google"
    assert_true "[[ \"$output\" == *\"Cloudflare\"* ]]" "--list shows Cloudflare"
}

# ==============================================================================
# TEST: Script Syntax
# ==============================================================================

test_syntax() {
    echo ""
    echo "========================================"
    echo "Testing: Script Syntax"
    echo "========================================"
    
    bash -n "$XDNS_SCRIPT" 2>/dev/null
    assert_exit_code 0 $? "Script has valid bash syntax"
}

test_lint() {
    echo ""
    echo "========================================"
    echo "Testing: ShellCheck Linting"
    echo "========================================"

    if ! command -v shellcheck &> /dev/null; then
        echo -e "${YELLOW}[!] ShellCheck not installed.${NC}"
        log_info "ShellCheck is recommended for code quality testing."
        read -rp "    Would you like to install it now? (y/n): " install_choice
        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            # We need root for installation, install_missing_deps handles the prompt
            # but the test script is usually run as non-root
            if [[ $EUID -ne 0 ]]; then
                log_info "Installation requires sudo privileges."
            fi
            if install_missing_deps "shellcheck"; then
                log_ok "ShellCheck installed successfully."
            else
                log_error "Failed to install ShellCheck."
                return 1
            fi
        else
            echo -e "${YELLOW}[SKIP] Skipping lint test.${NC}"
            return 0
        fi
    fi

    if command -v shellcheck &> /dev/null; then
        shellcheck "$XDNS_SCRIPT"
        assert_exit_code 0 $? "ShellCheck passed (no issues found)"
    fi
}

# ==============================================================================
# TEST: New Distro Support (v3.3.0)
# ==============================================================================

test_new_distros() {
    echo ""
    echo "========================================"
    echo "Testing: New Distro Package Manager Support"
    echo "========================================"
    
    # Check directly in the file to avoid eval issues with large content
    
    if grep -q "emerge" "$XDNS_SCRIPT"; then
        log_pass "Gentoo (emerge) supported"
    else
        log_fail "Gentoo (emerge) supported"
    fi
    ((TESTS_RUN++))

    if grep -q "xbps-install" "$XDNS_SCRIPT"; then
        log_pass "Void Linux (xbps-install) supported"
    else
        log_fail "Void Linux (xbps-install) supported"
    fi
    ((TESTS_RUN++))

    if grep -q "eopkg" "$XDNS_SCRIPT"; then
        log_pass "Solus (eopkg) supported"
    else
        log_fail "Solus (eopkg) supported"
    fi
    ((TESTS_RUN++))
    
    # Test NetworkManager persistence functions exist
    if grep -q "persist_dns_networkmanager" "$XDNS_SCRIPT"; then
        log_pass "persist_dns_networkmanager() exists"
    else
        log_fail "persist_dns_networkmanager() exists"
    fi
    ((TESTS_RUN++))

    if grep -q "remove_dns_persistence" "$XDNS_SCRIPT"; then
        log_pass "remove_dns_persistence() exists"
    else
        log_fail "remove_dns_persistence() exists"
    fi
    ((TESTS_RUN++))
    
    # Test systemd-networkd support
    if grep -q "systemd-networkd" "$XDNS_SCRIPT"; then
        log_pass "systemd-networkd support"
    else
        log_fail "systemd-networkd support"
    fi
    ((TESTS_RUN++))

    if grep -q "connman" "$XDNS_SCRIPT"; then
        log_pass "ConnMan support"
    else
        log_fail "ConnMan support"
    fi
    ((TESTS_RUN++))
}

# ==============================================================================
# TEST: Dependency Installation Logic (Mocking)
# ==============================================================================

test_install_logic() {
    echo ""
    echo "========================================"
    echo "Testing: Installation Logic (Mocked)"
    echo "========================================"

    # 1. Mock 'command' to simulate specific Distros
    #    We mock directly in current shell and unset later to avoid subshell scope issues
    
    # --- Case 1: Simulate Arch Linux (has 'pacman') ---
    
    # Override 'command'
    function command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "pacman" ]]; then return 0; fi
            if [[ "$2" == "apt-get" ]]; then return 1; fi
            # ... return 1 for others
        fi
        # Fallback to original command
        builtin command "$@"
    }
    
    # Override 'pacman'
    function pacman() {
        echo "MOCK_EXEC: pacman $*"
        return 0
    }
    
    # Override 'read'
    function read() {
        local var_name="${!#}"
        eval "${var_name}='y'"
    }

    # Run target function
    ((TESTS_RUN++))
    local output
    output=$(install_missing_deps "bc" "ping")
    
    if [[ "$output" == *"MOCK_EXEC: pacman -Sy --noconfirm"* ]]; then
        log_pass "Arch Logic: Detects pacman correctly"
    else
        log_fail "Arch Logic: Failed to detect pacman"
    fi
    
    ((TESTS_RUN++))
    if [[ "$output" == *"iputils"* ]]; then
        log_pass "Arch Logic: Maps 'ping' to 'iputils'"
    else
        log_fail "Arch Logic: Failed map 'ping' -> 'iputils'"
    fi

    # Cleanup mocks
    unset -f command pacman read

    # --- Case 2: Simulate Ubuntu/Debian (has 'apt-get') ---
    
    function command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "pacman" ]]; then return 1; fi
            if [[ "$2" == "apt-get" ]]; then return 0; fi
            return 1
        fi
        builtin command "$@"
    }
    
    function apt-get() {
        echo "MOCK_EXEC: apt-get $*"
        return 0
    }
    
    function read() {
        local var_name="${!#}"
        eval "${var_name}='y'"
    }

    ((TESTS_RUN++))
    output=$(install_missing_deps "shellcheck")
    
    if [[ "$output" == *"MOCK_EXEC: apt-get update"* ]]; then
         log_pass "Debian Logic: Runs apt-get update"
    else
         log_fail "Debian Logic: Missing apt-get update"
    fi

    # Cleanup mocks
    unset -f command apt-get read

    # --- Case 3: Simulate Fedora (has 'dnf') ---
    
    function command() {
        if [[ "$1" == "-v" ]]; then
            if [[ "$2" == "pacman" ]]; then return 1; fi
            if [[ "$2" == "apt-get" ]]; then return 1; fi
            if [[ "$2" == "dnf" ]]; then return 0; fi
            return 1
        fi
        builtin command "$@"
    }
    
    function dnf() {
        echo "MOCK_EXEC: dnf $*"
        return 0
    }
    
    function read() {
        local var_name="${!#}"
        eval "${var_name}='y'"
    }

    ((TESTS_RUN++))
    output=$(install_missing_deps "bc")
    
    if [[ "$output" == *"MOCK_EXEC: dnf install -y bc"* ]]; then
         log_pass "Fedora Logic: Runs dnf install"
    else
         log_fail "Fedora Logic: Failed dnf command"
    fi

    # Cleanup mocks
    unset -f command dnf read
}

# ==============================================================================
# MAIN
# ==============================================================================

main() {
    echo "=============================================="
    echo "  xdns Unit Tests"
    echo "  Script: $XDNS_SCRIPT"
    echo "=============================================="
    
    # Check script exists
    if [[ ! -f "$XDNS_SCRIPT" ]]; then
        echo -e "${RED}ERROR: xdns script not found at $XDNS_SCRIPT${NC}"
        exit 1
    fi
    
    # Source functions
    echo ""
    echo "Loading functions from xdns..."
    source_functions
    echo "Done."
    
    # Run tests
    test_syntax
    test_lint
    test_exit_codes
    test_constants
    test_validate_ipv4
    test_dns_providers
    test_cli_help
    test_new_distros
    test_install_logic
    
    # Summary
    echo ""
    echo "=============================================="
    echo "  TEST SUMMARY"
    echo "=============================================="
    echo -e "  Total:  ${TESTS_RUN}"
    echo -e "  ${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "  ${RED}Failed: ${TESTS_FAILED}${NC}"
    echo "=============================================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

main "$@"