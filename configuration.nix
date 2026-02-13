# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let

my-file = pkgs.writeShellScriptBin "my-awesome-script" ''
    #!/usr/bin/env bash
    echo "testing"
    cat /etc/passwd

'';

cage-startup-script = pkgs.writeShellScriptBin "cage-startup.sh" ''
  read -r url < /etc/startup-url
  ${pkgs.chromium}/bin/chromium --kiosk --start-maximized --start-fullscreen --no-first-run --noerrdialogs --disable-infobars $url
'';

kiosk-manager = pkgs.stdenvNoCC.mkDerivation {
  pname = "kiosk-manager";
  version = "0.2";

  src = pkgs.fetchurl {
    url = "https://revolve-kiosk-web-builds.s3.us-west-2.amazonaws.com/kiosk-manager-0.2.1";
    # Get this with: nix store prefetch-file https://...  (or nix-prefetch-url)
    sha256 = "sha256-0DnP/wN6trD3QU7QCnOLN8RnJQLd5d/wfNnFOwhW4xM=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    install -m 0755 $src $out/bin/kiosk-manager
  '';
};

# Edit this URL
  kioskUrl = "https://example.com";

  # Chromium launch script used as weston kiosk-shell client
  startKiosk = pkgs.writeShellScript "start-kiosk.sh" ''
    set -euo pipefail
    read -r url < /etc/startup-url

    exec ${pkgs.chromium}/bin/chromium \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform \
      --disable-features=WaylandWindowDecorations \
      --kiosk \
      --start-maximized \
      --no-first-run \
      --no-default-browser-check \
      --disable-infobars \
      --disable-session-crashed-bubble \
      --noerrdialogs \
      $url
  '';

  # Weston kiosk-shell config
  westonConfig = pkgs.writeText "weston.ini" ''
    [core]
    shell=${pkgs.weston}/lib/weston/kiosk-shell.so

    [shell]
    client=${startKiosk}

    [output]
    scale=1
  '';

in

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  hardware.enableAllFirmware = true;
  hardware.graphics.enable = true;

  # networking.hostName = "nixos"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Don't write the journal to the SD card
  # Comment this out if need to debug previous boot logs
  services.journald.storage = "volatile";

  boot.consoleLogLevel = lib.mkDefault 7;

  # The serial ports listed here are:
  # - ttyS0: for Tegra (Jetson TX1)
  # - ttyAMA0: for QEMU's -machine virt
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=ttyAMA0,115200n8"
    "console=tty0"
  ];

#  hardware.bluetooth.enable = false;
#  boot.blacklistedKernelModules = ["bluetooth"];


  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  security.sudo.wheelNeedsPassword = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.revolve = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "changeme";
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhHZiXRTjQfcrOAhME12N11ajU7Sl3bDdEMVX6Daquh"
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dcampano = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhHZiXRTjQfcrOAhME12N11ajU7Sl3bDdEMVX6Daquh"
    ];
  };

  users.motd = ''

==================================================

  Configuration of website url can be found
  at /etc/startup-url

  To adjust the launch url do the following steps

  1. sudo vim /etc/startup-url
  2. sudo systemctl restart weston-kiosk

==================================================

  '';

  # programs.firefox.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
  #  w3m-nographics # needed for the manual anyway
    testdisk # useful for repairing boot problems
    ms-sys # for writing Microsoft boot sectors / MBRs
    efibootmgr
    efivar
    parted
    gptfdisk
    ddrescue
    ccrypt
    cryptsetup # needed for dm-crypt volumes

    # Some text editors.
    vim

    # Some networking tools.
    fuse
    fuse3
    sshfs-fuse
    socat
    screen
    tcpdump

    # Hardware-related tools.
    sdparm
    hdparm
    smartmontools # for diagnosing hard disks
    pciutils
    usbutils
    nvme-cli

    # Some compression/archiver tools.
    unzip
    zip

    # Some utilities
    jq

    # Interact with HDMI CEC
    libcec
    v4l-utils

    # Needed for Kiosk Functionality
    wget
    chromium
    sysstat
    cage-startup-script
    cage # debugging this
    libraspberrypi
    raspberrypi-eeprom
    git
    weston
    wl-clipboard

    # Packages from the 'let' up top
    kiosk-manager

  ];

  # Create /etc/startup-url with default value if it doesn't exist
  systemd.tmpfiles.rules = [
    "f /etc/startup-url 0644 root root - https://tools.revolvepickleball.com/signage/courts-1-4"
  ];

  services.cage = {
    enable = false;
    user = "revolve";
    #user = "root";
    #program = "${pkgs.chromium}/bin/chromium --kiosk https://tools.revolvepickleball.com/signage/test";
    #program = "/home/revolve${cage-startup-script}";
    #program = "/home/revolve/launch.sh";
    extraArguments = [ "-d" ];
    program = "/run/current-system/sw/bin/cage-startup.sh";
    environment = {
      WLR_LIBINPUT_NO_DEVICES = "1";
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      AllowAgentForwarding = "yes";
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  systemd.services.kiosk-manager = {
    # These packages need to be added to the path
    # because the kiosk-manager calls commands from them
    path = with pkgs; [
      bash
      coreutils
      libcec
    ];
    serviceConfig = {
      User = "root";
      PrivateTmp = "true";
      ExecStart = "${kiosk-manager}/bin/kiosk-manager /etc/startup-url";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # Create a dedicated kiosk user (recommended)
  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = [ "video" "input" "render" "seat" ];
    # If you want to SSH in, add your key here.
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
  };

  #### Auto-login kiosk user on tty1
  services.getty.autologinUser = "kiosk";

  #### Optional but recommended: stop other ttys from stealing focus
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  #### Start Weston kiosk-shell automatically on boot
  systemd.services.weston-kiosk = {
    description = "Weston kiosk-shell session on tty1";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-user-sessions.service" "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      User = "kiosk";
      PAMName = "login";

      # Bind to tty1
      TTYPath = "/dev/tty1";
      StandardInput = "tty";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";

      # Environment for Wayland
      Environment = [
        "XDG_SESSION_TYPE=wayland"
        "XDG_RUNTIME_DIR=/run/user/%U"
      ];

      Restart = "always";
      RestartSec = 2;

      # Needed for DRM/input access on embedded boxes
      SupplementaryGroups = [ "video" "input" "render" ];
    };

    script = ''
      # Ensure runtime dir exists (usually handled by pam_systemd, but safe)
      mkdir -p /run/user/$(id -u)
      chmod 700 /run/user/$(id -u)

      # Run Weston with kiosk-shell
      exec ${pkgs.weston}/bin/weston --config=${westonConfig}
    '';
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}

