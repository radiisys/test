# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

        # Or define it inline, for example:
        (self: super: {
          waybar = super.waybar.overrideAttrs (oldAttrs: {
            mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
          });
        })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };

  # pain from here on out
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    steam.enable = true;
    nm-applet.enable = true;
    adb.enable = true;
    };

  environment.systemPackages = [
    pkgs.swayidle
    pkgs.gtklock
    (pkgs.python3.withPackages(ps: with ps; [ tkinter]))
    pkgs.temurin-jre-bin-8
    pkgs.temurin-bin-18
    pkgs.libinput
    pkgs.font-awesome
    (pkgs.discord-canary.override {
	withVencord = true;
    })
    pkgs.swaynotificationcenter
    pkgs.polkit_gnome
    pkgs.jetbrains-mono
    pkgs.libsForQt5.qt5ct
    pkgs.xdg-desktop-portal-hyprland
    pkgs.udiskie
    pkgs.adwaita-qt
    pkgs.adwaita-qt6
    pkgs.deepin.udisks2-qt5
    pkgs.cinnamon.nemo
    pkgs.waybar
  ];
  
  xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
    ];
  };
  security.pam.services.gtklock.text = lib.readFile "${pkgs.gtklock}/etc/pam.d/gtklock";
  
  services.mpd = {
    enable = true;
    user = "rion";
    extraConfig = ''
	audio_output {
    		type "pipewire"
    		name "My PipeWire Output"
        }
    '';
  };

  systemd.services.mpd.environment = {
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
    XDG_RUNTIME_DIR = "/run/user/1000"; # User-id 1000 must match above user. MPD will look inside this directory for the PipeWire socket.
  };

  fonts.packages = with pkgs; [
	font-awesome
	jetbrains-mono
  ];

  environment.variables = {
	QT_QPA_PLATFORMTHEME="qt5ct";
  };

  # TODO: Set your hostname
  networking.hostName = "Nebula";


  virtualisation.vmware.host.enable = true;

  # TODO: This is just an example, be sure to use whatever bootloader you prefer
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/";

  # enable networking
  networking.networkmanager.enable = true;

  # Set a time zone, idiot
  time.timeZone = "Europe/London";

  # Fun internationalisation stuffs (AAAAAAAA)
  i18n.defaultLocale = "it_IT.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Enable X11 Windowing system
  services.xserver.enable = true;
  # Enable display Manager
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;

  # configure keymap (x11)
  services.xserver = {
    layout = "gb";
    xkbVariant = "colemak";
  };

  # Would you like to be able to fucking print?
  services.printing.enable = true;

  # Sound (kill me now)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.polkit.enable = true;

 systemd = {
  user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
  };
};

  services.lvm.enable = true;

  # define user acc
  users.users.rion = {
    isNormalUser = true;
    description = "Rion";
    extraGroups = ["networkmanager" "wheel" "adbusers"];
    openssh.authorizedKeys.keys = [
      # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    ];
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh.settings = {
    enable = true;
    # Forbid root login through SSH.
    permitRootLogin = "yes";
    # Use keys only. Remove if you want to SSH using password (not recommended)
    passwordAuthentication = true;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
