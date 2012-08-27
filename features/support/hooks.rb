After do
  [:visitors, :aliens, :visits, :users, :sessions, :documents].each do |collection|
    @DB[collection].drop
  end
  Fast.dir.remove! :test, :fixtures
end
