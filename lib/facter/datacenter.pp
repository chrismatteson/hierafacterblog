Facter.add(:datacenter) do
  setcode do
    Facter.value(:hostname)[0..3]
  end
end
