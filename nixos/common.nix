# What every machine of mine runs, whatever it runs on: the desktop (desktop.nix) and the
# applications, dev tools and services (apps.nix).  configuration.nix (Weaselway on WSL,
# x86_64) and otterway.nix's nixos#otterway (Otterway on a Mac, aarch64) import it.
{
  imports = [ ./desktop.nix ./apps.nix ];
}
