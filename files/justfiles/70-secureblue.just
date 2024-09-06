# Add additional boot parameters for hardening (requires reboot)
set-kargs-hardening:
    #!/usr/bin/pkexec /usr/bin/bash
    rpm-ostree kargs \
      --append-if-missing="init_on_alloc=1" \
      --append-if-missing="init_on_free=1" \
      --append-if-missing="slab_nomerge" \
      --append-if-missing="page_alloc.shuffle=1" \
      --append-if-missing="randomize_kstack_offset=on" \
      --append-if-missing="vsyscall=none" \
      --append-if-missing="lockdown=confidentiality" \
      --append-if-missing="random.trust_cpu=off" \
      --append-if-missing="random.trust_bootloader=off" \
      --append-if-missing="iommu=force" \
      --append-if-missing="intel_iommu=on" \
      --append-if-missing="amd_iommu=force_isolation" \
      --append-if-missing="iommu.passthrough=0" \
      --append-if-missing="iommu.strict=1" \
      --append-if-missing="pti=on" \
      --append-if-missing="module.sig_enforce=1" \
      --append-if-missing="mitigations=auto,nosmt" \
      --append-if-missing="spectre_v2=on" \
      --append-if-missing="spec_store_bypass_disable=on" \
      --append-if-missing="l1d_flush=on" \
      --append-if-missing="gather_data_sampling=force"
    echo "Hardening kargs set."

# Add additional (unstable) boot parameters for hardening (requires reboot)
set-kargs-hardening-unstable:
    #!/usr/bin/pkexec /usr/bin/bash
    echo "Warning: setting these kargs may lead to boot issues on some hardware."
    rpm-ostree kargs \
      --append-if-missing="efi=disable_early_pci_dma" \
      --append-if-missing="debugfs=off"

    echo "Unstable hardening kargs set."

# Remove all hardening boot parameters (requires reboot)
remove-kargs-hardening:
    #!/usr/bin/pkexec /usr/bin/bash
    rpm-ostree kargs \
      --delete-if-present="init_on_alloc=1" \
      --delete-if-present="init_on_free=1" \
      --delete-if-present="slab_nomerge" \
      --delete-if-present="page_alloc.shuffle=1" \
      --delete-if-present="randomize_kstack_offset=on" \
      --delete-if-present="vsyscall=none" \
      --delete-if-present="lockdown=confidentiality" \
      --delete-if-present="random.trust_cpu=off" \
      --delete-if-present="random.trust_bootloader=off" \
      --delete-if-present="iommu=force" \
      --delete-if-present="intel_iommu=on" \
      --delete-if-present="amd_iommu=force_isolation" \
      --delete-if-present="iommu.passthrough=0" \
      --delete-if-present="iommu.strict=1" \
      --delete-if-present="pti=on" \
      --delete-if-present="module.sig_enforce=1" \
      --delete-if-present="mitigations=auto,nosmt" \
      --delete-if-present="efi=disable_early_pci_dma" \
      --delete-if-present="debugfs=off" \
      --delete-if-present="spectre_v2=on" \
      --delete-if-present="spec_store_bypass_disable=on" \
      --delete-if-present="l1d_flush=on" \
      --delete-if-present="gather_data_sampling=force"
    echo "Hardening kargs removed."

# Toggle the cups service on/off
toggle-cups:
    #!/usr/bin/pkexec /usr/bin/bash
    if systemctl is-enabled --quiet cups; then
      firewall-cmd --permanent --remove-port=631/tcp
      firewall-cmd --permanent --remove-port=631/udp
      firewall-cmd --reload
      systemctl mask cups
      systemctl disable cups
      systemctl stop cups
      systemctl daemon-reload
      echo "Cups disabled."
    else
      firewall-cmd --permanent --add-port=631/tcp
      firewall-cmd --permanent --add-port=631/udp
      firewall-cmd --reload
      systemctl unmask cups
      systemctl enable cups
      systemctl start cups
      systemctl daemon-reload
      echo "Cups enabled."
    fi

# Toggle bluetooth kernel modules on/off (requires reboot)
toggle-bluetooth-modules:
    #!/usr/bin/pkexec /usr/bin/bash
    BLUE_MOD_FILE="/etc/modprobe.d/99-bluetooth.conf"
    if test -e $BLUE_MOD_FILE; then
      sudo rm -f $BLUE_MOD_FILE
      echo "Bluetooth kernel modules disabled. Reboot to take effect."
    else
      sudo sh -c 'echo "install bluetooth /sbin/modprobe --ignore-install bluetooth" >> "$1"' _ "$BLUE_MOD_FILE"
      sudo sh -c 'echo "install btusb /sbin/modprobe --ignore-install btusb" >> "$1"' _ "$BLUE_MOD_FILE"
      sudo chmod 644 $BLUE_MOD_FILE
      echo "Bluetooth kernel modules enabled. Reboot to take effect."
    fi

# enable a kernel module that is disabled by modprobe.d (requires restart)
override-enable-module mod_name:
    #!/usr/bin/pkexec /usr/bin/bash
    MOD_NAME="{{ mod_name }}"
    MOD_FILE="/etc/modprobe.d/99-$MOD_NAME.conf"
    if test -e $MOD_FILE; then
      echo "$MOD_NAME module is already enabled."
    else
      sudo sh -c 'echo "install $1 /sbin/modprobe --ignore-install $1" >> "$2"' _ "$MOD_NAME" "$MOD_FILE"
      sudo chmod 644 $MOD_FILE
      echo "Override created to enable $MOD_NAME module. Reboot to take effect."
    fi

# reset the override by `just override-enable-module`, i.e. disable the module again (requires restart)
override-reset-module mod_name:
    #!/usr/bin/pkexec /usr/bin/bash
    MOD_NAME="{{ mod_name }}"
    MOD_FILE="/etc/modprobe.d/99-$MOD_NAME.conf"
    if test -e $MOD_FILE; then
      sudo rm -f $MOD_FILE
      echo "The override for $MOD_NAME module has been reset. Reboot to take effect."
    else
      echo "No override found for $MOD_NAME module."
    fi

# Rerun Yafti
rerun-yafti:
    yafti -f /usr/share/ublue-os/firstboot/yafti.yml

# Toggle anticheat support by changing ptrace scope (requires restart)
toggle-anticheat-support:
    #!/usr/bin/pkexec /usr/bin/bash
    SYSCTL_HARDENING_FILE="/etc/sysctl.d/hardening.conf"
    if grep -q "kernel.yama.ptrace_scope = 3" "$SYSCTL_HARDENING_FILE"; then
        sed -i "s/kernel.yama.ptrace_scope = 3/kernel.yama.ptrace_scope = 1/" "$SYSCTL_HARDENING_FILE"
        echo "Anticheat support enabled. ptrace_scope set to 1."
    elif grep -q "kernel.yama.ptrace_scope = 1" "$SYSCTL_HARDENING_FILE"; then
        sed -i "s/kernel.yama.ptrace_scope = 1/kernel.yama.ptrace_scope = 3/" "$SYSCTL_HARDENING_FILE"
        echo "Anticheat support disabled. ptrace_scope set back to 3."
    else
        echo "The sysctl hardening file is missing the ptrace_scope setting."
    fi
