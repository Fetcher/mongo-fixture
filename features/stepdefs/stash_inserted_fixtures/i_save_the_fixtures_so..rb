And /^I load the (\w+) fixture to be stashed$/ do |which|
  Mongo::Fixture.new which.to_sym, @DB, :stash => true
end

When /^I rollback the stashed fixtures$/ do 
  Mongo::Fixture.stashed.each do |fixture|
    fixture.rollback
  end
end