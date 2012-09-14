#!/usr/bin/env rspec

require 'spec_helper'

provider_class = Puppet::Type.type(:syslog).provider(:augeas)

describe provider_class do
  context "with empty file" do
    let(:tmptarget) { aug_fixture("empty") }
    let(:target) { tmptarget.path }

    it "should create simple new entry" do
      apply!(Puppet::Type.type(:syslog).new(
        :name        => "my test",
        :facility    => "local2",
        :level       => "*",
        :action_type => "file",
        :action      => "/var/log/test.log",
        :target      => target,
        :provider    => "augeas",
        :ensure      => "present"
      ))

      aug_open(target, "Syslog.lns") do |aug|
        aug.match("entry").size.should == 1
        aug.get("entry/action/file").should == "/var/log/test.log"
        aug.match("entry/action/no_sync").size.should == 0
      end
    end
  end

  context "with full file" do
    let(:tmptarget) { aug_fixture("full") }
    let(:target) { tmptarget.path }

    describe "when creating settings" do
      it "should create a simple new entry" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "my test",
          :facility    => "local2",
          :level       => "info",
          :action_type => "file",
          :action      => "/var/log/test.log",
          :target      => target,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Syslog.lns") do |aug|
          aug.get("entry[selector/facility='local2']/action/file").should == "/var/log/test.log"
          aug.match("entry[selector/facility='local2']/action/no_sync").size.should == 0
        end
      end
    end

    describe "when modifying settings" do
      it "should add a no_sync flag" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "cron.*",
          :facility    => "cron",
          :level       => "*",
          :action_type => "file",
          :action      => "/var/log/cron",
          :target      => target,
          :no_sync     => :true,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Syslog.lns") do |aug|
          aug.match("entry[selector/facility='cron']/action/no_sync").size.should == 1
        end
      end

      it "should remove the no_sync flag" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "mail.*",
          :facility    => "mail",
          :level       => "*",
          :action_type => "file",
          :action      => "/var/log/maillog",
          :target      => target,
          :no_sync     => :false,
          :provider    => "augeas",
          :ensure      => "present"
        ))

        aug_open(target, "Syslog.lns") do |aug|
          aug.match("entry[selector/facility='mail']/action/no_sync").size.should == 0
        end
      end
    end

    describe "when removing settings" do
      it "should remove the entry" do
        apply!(Puppet::Type.type(:syslog).new(
          :name        => "mail.*",
          :facility    => "mail",
          :level       => "*",
          :action_type => "file",
          :action      => "/var/log/maillog",
          :target      => target,
          :provider    => "augeas",
          :ensure      => "absent"
        ))

        aug_open(target, "Syslog.lns") do |aug|
          aug.match("entry[selector/facility='mail' and level='*']").size.should == 0
        end
      end
    end
  end

  context "with broken file" do
    let(:tmptarget) { aug_fixture("broken") }
    let(:target) { tmptarget.path }

    it "should fail to load" do
      txn = apply(Puppet::Type.type(:syslog).new(
        :name        => "mail.*",
        :facility    => "mail",
        :level       => "*",
        :action_type => "file",
        :action      => "/var/log/maillog",
        :target      => target,
        :provider    => "augeas",
        :ensure      => "present"
      ))

      txn.any_failed?.should_not == nil
      @logs.first.level.should == :err
      @logs.first.message.include?(target).should == true
    end
  end
end
