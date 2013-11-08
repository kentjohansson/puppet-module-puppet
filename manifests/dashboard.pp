# == Class: puppet::dashboard
#
class puppet::dashboard (
  $dashboard_package         = 'puppet-dashboard',
  $dashboard_user            = 'puppet-dashboard',
  $dashboard_group           = 'puppet-dashboard',
  $sysconfig_path            = 'USE_DEFAULTS',
  $external_node_script_path = '/usr/share/puppet-dashboard/bin/external_node',
  $dashboard_fqdn            = "puppet.${::domain}",
  $port                      = '3000',
) {

  validate_absolute_path($external_node_script_path)

  case $::osfamily {
    'RedHat': {
      $default_sysconfig_path = '/etc/sysconfig/puppet-dashboard'
    }
    'Debian': {
      $default_sysconfig_path = '/etc/default/puppet-dashboard'
    }
    default: {
      fail("puppet::dashboard supports osfamilies Debian and RedHat. Detected osfamily is <${::osfamily}>.")
    }
  }

  if $sysconfig_path == 'USE_DEFAULTS' {
    $sysconfig_path_real = $default_sysconfig_path
  } else {
    $sysconfig_path_real = $sysconfig_path
  }

  package { 'puppet_dashboard':
    ensure => present,
    name   => $dashboard_package,
  }

  file { 'external_node_script':
    ensure  => file,
    content => template('puppet/external_node.erb'),
    path    => $external_node_script_path,
    owner   => $dashboard_user,
    group   => $dashboard_group,
    mode    => '0755',
    require => Package['puppet_dashboard'],
  }

  file { 'dashboard_sysconfig':
    ensure  => file,
    path    => $sysconfig_path_real,
    content => template('puppet/dashboard_sysconfig.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  # Dashboard is ran under Passenger with Apache
  service { 'puppet-dashboard':
    ensure    => stopped,
    enable    => false,
    subscribe => File['dashboard_sysconfig'],
  }

  service { 'puppet-dashboard-workers':
    ensure    => stopped,
    enable    => false,
  }
}
