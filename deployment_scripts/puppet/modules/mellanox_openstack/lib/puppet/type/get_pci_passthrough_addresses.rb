Facter.add(:get_pci_passthrough_addresses) do
  setcode do
    $physnet = args[0]
    $exclude_vf = args[1]
    Facter::Util::Resolution.exec("python /etc/fuel/plugins/mellanox-plugin-*.0/generate_pci_passthrough_whitelist.py $exclude_vf $physnet")
  end
end

