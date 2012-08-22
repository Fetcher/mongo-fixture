require "spec_helper"

describe Mongo::Fixture do
  context "two collections are to be inserted with references" do
    before do 
      Fast.file.write "test/fixtures/references/users.yaml", "pepe:
  username: pepe
  password: 
  raw: secreto
  processed: 252db48960f032db4bb604bc26f97106fa85ff88dedef3a28671b6bcd9f9644bf90d7e444d587c9351dfa237a6fc8fe38641a8469d084a166c7807d9c6564860
  name: Pepe"
      Fast.file.write "test/fixtures/references/sessions.yaml", "14_horas:
  user: 
  users: pepe
  time: 2012-07-30T14:02:40-03:00
  y_tres_minutos:
  user: 
  users: pepe
  time: 2012-07-30T14:03:40-03:00
  y_cuatro_minutos:
  user: 
  users: pepe
  time: 2012-07-30T14:04:40-03:00"
    end

    it "should not fail!" do
      collection = double 'coll', :count => 0, :insert => nil
      database = double 'database'
      database.stub :[] do |argument|
        collection
      end
      Mongo::Fixture.new :references, database
    end

    after do
      Fast.dir.remove! :test
    end
  end

  context "many to many associations" do
    pending "refactoring" do
      before do
        Fast.file.write "test/fixtures/associations/users.yaml", "johnny:
    name: John
    documents:
      documents: [brief, docs, extra_data]
  susan:
    name: Susan
    documents:
      documents: [brief, resume, docs]"
        Fast.file.write "test/fixtures/associations/documents.yaml", "brief:
    title: Data
    text: Resumee
  docs:
    title: Doc
    text: Documentation
  extra_data:
    title: Xtra
    text: More and more data
  resume:
    title: CV
    text: Curriculum Vitae"
      end

      it "should not fail" do
        collection = double 'coll', :count => 0, :insert => nil
        database = double 'database'
        database.stub :[] do |argument|
          collection
        end
        Mongo::Fixture.new :associations, database
      end

      after do
        Fast.dir.remove! :test
      end
    end
  end
end
