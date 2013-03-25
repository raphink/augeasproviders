# Manages entries in /etc/sysctl.conf
#
# Copyright (c) 2012 Dominic Cleal
# Licensed under the Apache License, Version 2.0

Puppet::Type.newtype(:sysctl) do
  @doc = "Manages entries in /etc/sysctl.conf."

  ensurable

  def munge_boolean(value)
    case value
    when true, "true", :true
      :true
    when false, "false", :false
      :false
    else
      fail("munge_boolean only takes booleans")
    end
  end

  newparam(:name) do
    desc "The name of the setting, e.g. net.ipv4.ip_forward"
    isnamevar
  end

  newproperty(:value) do
    desc "Value to change the setting to. Settings with multiple values (such as net.ipv4.tcp_mem are represented as a single whitespace separated string."
  end

  newparam(:target) do
    desc "The file in which to store the settings, defaults to
      `/etc/sysctl.conf`."
  end

  newproperty(:comment) do
    desc "Text to be stored in a comment immediately above the entry.  It will be automatically prepended with the name of the setting in order for the provider to know whether it controls the comment or not."
  end

  newparam(:apply) do
    desc "Whether to apply the value using the sysctl command."

    validate do |value|
      unless value =~ /^(true|false)$/
        raise ArgumentError, "Apply must be a boolean"
      end
    end
    defaultto(:true)

    munge do |value|
      @resource.munge_boolean(value)
    end
  end
end
