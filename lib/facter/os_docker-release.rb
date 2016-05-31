['designate', 'glance', 'heat', 'neutron', 'nova', 'keystone']. each do |project|
  if File.readable?("/etc/#{project}/release_name")
    Facter.add("#{project}_release") do
      setcode do
        File.read("/etc/#{project}/release_name").strip
      end
    end
  end

  if File.readable?("/etc/#{project}/version")
    Facter.add("#{project}_version") do
      setcode do
        File.read("/etc/#{project}/version").strip
      end
    end
  end
end
