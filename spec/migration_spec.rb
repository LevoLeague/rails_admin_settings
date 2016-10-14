# encoding: utf-8

require 'spec_helper'

describe 'Migrating from old versions' do
  it 'sets ns' do
    coll = RailsAdminSettings::Setting.collection
    if coll.respond_to?(:insert_one)
      coll.insert_one({enabled: true, key: 'test', raw: '9060000000', type: 'phone'})
    else
      coll.insert({enabled: true, key: 'test', raw: '9060000000', type: 'phone'})
    end
    RailsAdminSettings.migrate!
    RailsAdminSettings::Setting.first.key.should eq 'test'
    RailsAdminSettings::Setting.first.raw.should eq '9060000000'
    RailsAdminSettings::Setting.first.ns.should eq 'main'
    RailsAdminSettings::Setting.first.kind.should eq 'phone'
  end
end

