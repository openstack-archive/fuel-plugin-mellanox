if $osfamily == "RedHat" {
  $devel_packages=["kernel-devel", "kernel-lt-devel"]
  package{ $devel_packages:
    ensure => installed
  }
}
