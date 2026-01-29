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
    
    # Extract function definitions (skip main call at the end)
    sed '/^main "\$@"$/d' "$XDNS_SCRIPT" > "$tmp_file"
    
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
    assert_true "[[ \"\$output\" == *\"Google\"* ]]" "Provider 1 exists (Google)"
    assert_true "[[ \"\$output\" == *\"Cloudflare\"* ]]" "Provider 2 exists (Cloudflare)"
    assert_true "[[ \"\$output\" == *\"Quad9\"* ]]" "Provider 4 exists (Quad9)"
    assert_true "[[ \"\$output\" == *\"AdGuard\"* ]]" "Provider 5 exists (AdGuard)"
    assert_true "[[ \"\$output\" == *\"OpenDNS\"* ]]" "Provider 6 exists (OpenDNS)"
    assert_true "[[ \"\$output\" == *\"Verisign\"* ]]" "Provider 7 exists (Verisign)"
    
    # Check IPs appear in list
    assert_true "[[ \"\$output\" == *\"8.8.8.8\"* ]]" "Google DNS IP shown"
    assert_true "[[ \"\$output\" == *\"1.1.1.1\"* ]]" "Cloudflare DNS IP shown"
    assert_true "[[ \"\$output\" == *\"9.9.9.9\"* ]]" "Quad9 DNS IP shown"
}

# ==============================================================================
# TEST: Constants
# ==============================================================================

test_constants() {
    echo ""
    echo "========================================"
    echo "Testing: Constants Definition"
    echo "========================================"
    
    assert_true "[[ -n \"\$VERSION\" ]]" "VERSION is defined"
    assert_true "[[ \"\$VERSION\" == \"3.2.0\" ]]" "VERSION is 3.2.0"
    
    assert_true "[[ -n \"\$RESOLV_CONF\" ]]" "RESOLV_CONF is defined"
    assert_equals "/etc/resolv.conf" "$RESOLV_CONF" "RESOLV_CONF path correct"
    
    assert_true "[[ -n \"\$BACKUP_DIR\" ]]" "BACKUP_DIR is defined"
    assert_equals "/var/backups/xdns" "$BACKUP_DIR" "BACKUP_DIR path correct"
    
    # Network constants
    assert_true "[[ \"\$PING_COUNT\" -gt 0 ]]" "PING_COUNT is positive"
    assert_true "[[ \"\$PING_TIMEOUT\" -gt 0 ]]" "PING_TIMEOUT is positive"
    assert_true "[[ \"\$LATENCY_FAST\" -gt 0 ]]" "LATENCY_FAST is positive"
    assert_true "[[ \"\$LATENCY_MEDIUM\" -gt \"\$LATENCY_FAST\" ]]" "LATENCY_MEDIUM > LATENCY_FAST"
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
    assert_true "[[ \"\$output\" == *\"USAGE\"* ]]" "--help contains USAGE"
    assert_true "[[ \"\$output\" == *\"OPTIONS\"* ]]" "--help contains OPTIONS"
    
    # Version should work without root
    output=$("$XDNS_SCRIPT" --version 2>&1)
    assert_exit_code 0 $? "--version exits with 0"
    assert_true "[[ \"\$output\" == *\"3.2.0\"* ]]" "--version shows 3.2.0"
    
    # List should work without root
    output=$("$XDNS_SCRIPT" --list 2>&1)
    assert_exit_code 0 $? "--list exits with 0"
    assert_true "[[ \"\$output\" == *\"Google\"* ]]" "--list shows Google"
    assert_true "[[ \"\$output\" == *\"Cloudflare\"* ]]" "--list shows Cloudflare"
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
    test_exit_codes
    test_constants
    test_validate_ipv4
    test_dns_providers
    test_cli_help
    
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
