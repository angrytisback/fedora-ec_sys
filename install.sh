#!/bin/bash

set -o pipefail

MODULE_NAME="ec_sys"
KERNEL_VERSION=$(uname -r)
WORK_DIR=$(mktemp -d -t ec_sys_build.XXXXXX)
INSTALL_DIR="/lib/modules/${KERNEL_VERSION}/extra"
SOURCE_RPM="kernel-core-${KERNEL_VERSION}"

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cleanup() {
  if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
  fi
  rm -f ec_sys.c internal.h ec_sys.o ec_sys.mod* modules.order Module.symvers ec_sys.ko .*.cmd
}

log_info() {
  echo -e "${GREEN}[INFO] $1${NC}"
}

log_warn() {
  echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_error() {
  echo -e "${RED}[ERROR] Command failed: '$BASH_COMMAND'${NC}"
  cleanup
  exit 1
}

trap cleanup EXIT
trap 'log_error' ERR

echo -e "${BOLD}Fedora ec_sys Module Installer${NC}"
echo -e "Target Kernel: ${KERNEL_VERSION}\n"

if [[ $EUID -ne 0 ]]; then
  log_error "This script must be executed with root privileges (sudo)."
fi

log_info "Checking system configuration..."

SKIP_BUILD=false

if modinfo -n "${MODULE_NAME}" &>/dev/null; then
  echo "       > The '${MODULE_NAME}' module is already installed."
  SKIP_BUILD=true
fi

if [ -f "/boot/config-${KERNEL_VERSION}" ]; then
  CONFIG_STATUS=$(grep "^CONFIG_ACPI_EC_DEBUG" "/boot/config-${KERNEL_VERSION}" || true)
  if [[ "$CONFIG_STATUS" == *"=y"* ]]; then
    log_warn "The driver is compiled as built-in (=y). Modprobe options may not function as expected."
    SKIP_BUILD=true
  fi
fi

if [ "$SKIP_BUILD" = false ]; then

  if command -v mokutil &>/dev/null; then
    SB_STATE=$(mokutil --sb-state)
    if [[ "$SB_STATE" == *"enabled"* ]]; then
      log_warn "Secure Boot is ENABLED."
      echo "          The compiled module will be unsigned and may fail to load."
      echo "          Please refer to SIGNING.md for instructions on signing the module."
      read -p "          Press ENTER to proceed with compilation, or Ctrl+C to abort..."
    fi
  fi

  log_info "Installing build dependencies..."
  dnf install -y --skip-broken \
    kernel-devel-"${KERNEL_VERSION}" \
    kernel-headers \
    gcc make dnf-utils rpm-build cpio tar || log_error

  log_info "Retrieving kernel source code..."
  cd "$WORK_DIR"

  echo "       > Downloading source RPM for ${KERNEL_VERSION}..."
  dnf download --source "$SOURCE_RPM" || log_error

  echo "       > Extracting source archive..."
  rpm2cpio kernel-*.src.rpm | cpio -idmv --quiet
  TAR_FILE=$(ls linux-*.tar.xz)

  if [ -z "$TAR_FILE" ]; then
    echo -e "${RED}[ERROR] Linux tarball not found within the source RPM.${NC}"
    cleanup
    exit 1
  fi

  tar -xf "$TAR_FILE" --wildcards '*/drivers/acpi/ec_sys.c' '*/drivers/acpi/internal.h' --strip-components=3

  mv ec_sys.c internal.h "$OLDPWD/"
  cd "$OLDPWD"

  log_info "Compiling kernel module..."
  make clean >/dev/null
  make || log_error

  if [ ! -f "${MODULE_NAME}.ko" ]; then
    echo -e "${RED}[ERROR] Module binary (.ko) was not generated.${NC}"
    cleanup
    exit 1
  fi

  log_info "Installing module binary..."
  mkdir -p "$INSTALL_DIR"
  cp "${MODULE_NAME}.ko" "$INSTALL_DIR/"
  depmod -a || log_error

else
  log_info "Skipping build process (Module already exists)."
fi

log_info "Configuring system persistence..."

echo "${MODULE_NAME}" >/etc/modules-load.d/${MODULE_NAME}.conf
echo "       > Created /etc/modules-load.d/${MODULE_NAME}.conf"

echo "options ${MODULE_NAME} write_support=1" >/etc/modprobe.d/${MODULE_NAME}.conf
echo "       > Created /etc/modprobe.d/${MODULE_NAME}.conf (write_support=1)"

log_info "Attempting to load module..."
modprobe -r "${MODULE_NAME}" 2>/dev/null

if modprobe "${MODULE_NAME}" write_support=1; then
  echo -e "\n${GREEN}SUCCESS: The module is active and loaded.${NC}"
  echo "       Verification Command: sudo hexdump -C /sys/kernel/debug/ec/ec0/io"
else
  echo -e "\n${RED}WARNING: The module failed to load.${NC}"
  echo "         If Secure Boot is active, ensure the module is signed (see SIGNING.md)."
  echo "         Alternatively, reboot the system."
fi
