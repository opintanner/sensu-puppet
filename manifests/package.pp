# = Class: sensu::package
#
# Installs the Sensu packages
#
class sensu::package {

  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  case $::osfamily {

    'Debian': {
      class { '::sensu::repo::apt': }
      if $sensu::install_repo {
        include ::apt
      }
    }

    'RedHat': {
      class { '::sensu::repo::yum': }
    }

    default: { fail("${::osfamily} not supported yet") }

  }

  if $sensu::install_repo {
    package { 'sensu':
      ensure  => $sensu::version,
    }
  } else {
    package { 'sensu':
      ensure   => $sensu::version,
      provider => gem,
    }
  }

  if $::sensu::sensu_plugin_provider {
    $plugin_provider = $::sensu::sensu_plugin_provider
  } else {
    $plugin_provider = $sensu::use_embedded_ruby ? {
      true    => 'sensu_gem',
      default => 'gem',
    }
  }

  if $plugin_provider =~ /gem/ and $::sensu::gem_install_options {
    package { $::sensu::sensu_plugin_name :
      ensure          => $sensu::sensu_plugin_version,
      provider        => $plugin_provider,
      install_options => $::sensu::gem_install_options,
    }
  } else {
    package { $::sensu::sensu_plugin_name :
      ensure   => $sensu::sensu_plugin_version,
      provider => $plugin_provider,
    }
  }

  file { '/etc/default/sensu':
    ensure  => file,
    content => template("${module_name}/sensu.erb"),
    owner   => '0',
    group   => '0',
    mode    => '0444',
    require => Package['sensu'],
  }

  file { [ '/etc/sensu/conf.d', '/etc/sensu/conf.d/handlers', '/etc/sensu/conf.d/checks', '/etc/sensu/conf.d/filters', '/etc/sensu/conf.d/extensions' ]:
    ensure  => directory,
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0555',
    purge   => $sensu::_purge_config,
    recurse => true,
    force   => true,
    require => Package['sensu'],
  }

  file { '/etc/sensu/handlers':
    ensure  => directory,
    mode    => '0555',
    owner   => 'sensu',
    group   => 'sensu',
    purge   => $sensu::_purge_handlers,
    recurse => true,
    force   => true,
    require => Package['sensu'],
  }

  file { ['/etc/sensu/extensions', '/etc/sensu/extensions/handlers']:
    ensure  => directory,
    mode    => '0555',
    owner   => 'sensu',
    group   => 'sensu',
    purge   => $sensu::_purge_extensions,
    recurse => true,
    force   => true,
    require => Package['sensu'],
  }

  file { '/etc/sensu/mutators':
    ensure  => directory,
    mode    => '0555',
    owner   => 'sensu',
    group   => 'sensu',
    purge   => $sensu::_purge_mutators,
    recurse => true,
    force   => true,
    require => Package['sensu'],
  }

  if $sensu::_manage_plugins_dir {
    file { '/etc/sensu/plugins':
      ensure  => directory,
      mode    => '0555',
      owner   => 'sensu',
      group   => 'sensu',
      purge   => $sensu::_purge_plugins,
      recurse => true,
      force   => true,
      require => Package['sensu'],
    }
  }

  if $sensu::manage_user {
    user { 'sensu':
      ensure  => 'present',
      system  => true,
      home    => '/opt/sensu',
      shell   => '/bin/false',
      comment => 'Sensu Monitoring Framework',
    }

    group { 'sensu':
      ensure => 'present',
      system => true,
    }
  }

  file { '/etc/sensu/config.json': ensure => absent }
}
