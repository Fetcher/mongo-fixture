After do
  [:visitors, :aliens, :visits].each do |collection|
    @DB[collection].drop
  end
  Fast.dir.remove! :test, :fixtures
end
