## Secure boot signing guide

To utilize the `ec_sys` module while Secure Boot is enabled, the compiled kernel object `(.ko)` must be cryptographically signed, and the corresponding public key must be enrolled in the system's Machine Owner Key (MOK) list.

1. ### Install Utilities

```bash
sudo dnf install openssl keyutils mokutil
```

2. ### Generate Key Pair

```bash

# Create OpenSSL configuration
cat << EOF > x509.genkey
[req ]
default_bits = 4096
distinguished_name = req_distinguished_name
prompt = no
string_mask
=
utf8only
x509_extensions
= myexts
[req_distinguished_name ]
0 = Fedora ec_sys Wrapper CN = Fedora ec_sys Wrapper MOK
[ myexts ]
basicConstraints-critical, CA: FALSE
keyUsage=digitalSignature
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
EOF
# Generate keys
openssl req -new -nodes -utf8 -sha256 -days 36500 -batch -x509 -config x509.genkey -outfo
```

3.  ### Enroll Key in BIOS

```bash
sudo mokutil --import MOK.der
```

- Restart the computer. During boot, the shim UEFI Key Management screen (blue screen) will appear.
- Select **Enroll MOK**
- Select **Continue**
- Select **Yes** to confirm
- Enter the password you set in the previous command
- Select **Reboot**

4.  ### Sign The Module
    After boot, sign the compiled module using the keys generated in section 2.

```bash
# Locate the installed module
MOD_PATH=$(find /lib/modules/$(uname -r) -name "ec_sys.ko")

# Execute the kernel signing script
sudo /lib/modules/$(uname -r)/build/scripts/sign-file sha256 MOK.priv MOK.der "$MOD_PATH"
```

6.  ### Load The Module
    Reload the module to apply changes.

```bash
sudo modprobe -r ec_sys
sudo modprobe ec_sys write_support=1
```
