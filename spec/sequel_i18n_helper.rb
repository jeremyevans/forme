require File.join(File.dirname(File.expand_path(__FILE__)), 'sequel_helper.rb')

gem 'i18n', '>= 0.7.0'
require 'i18n'
I18n.load_path = [File.join(File.dirname(File.expand_path(__FILE__)), 'i18n_helper.yml')] 

DB.create_table(:firms) do
  primary_key :id
  String :name
end
DB.create_table(:invoices) do
  primary_key :id
  foreign_key :firm_id, :firms
  String :name
  String :summary
end
DB.create_table(:clients) do
  primary_key :id
  foreign_key :firm_id, :firms
  String :name
end

a = DB[:firms].insert(:name=>'a')
DB[:invoices].insert(:name=>'b', :firm_id=>a, :summary=>'a brief summary')
DB[:clients].insert(:name=>'a great client', :firm_id=>a)

class Firm < Sequel::Model
  one_to_many :invoices
  one_to_many :clients
end

class Invoice < Sequel::Model
  many_to_one :firm
end

class Client < Sequel::Model
  many_to_one :firm
end

[Firm, Invoice, Client].each{|c| c.plugin :forme_i18n }
