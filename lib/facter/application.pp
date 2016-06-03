Facter.add(:application) do
  setcode do
    Facter.value(:hostname)[5..-1][/(.*?)(\-|\z)/,1]
  end
end
