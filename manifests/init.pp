# == Defined class: users
#
# Users configuration module
#
# === Parameters
#
# [*user*]
#   User name, defaults to the resource name if not present.
#
# [*groups*]
#   Groups to which the user belongs. Primary group should not be listed here.
#
# [*uid*]
#   User ID
#
# [*gid*]
#   Group ID
#
# [*group*]
#   Primary group name.
#
# [*homepath*]
#   Home dir path, defaults to '/home'
#
# [*authorized_keys*]
#   Hash of optional authorized keys. Example:
#   { "root-key-1" => { key => '<public key>', type => 'rsa', user => 'root' } }
#
# [*keys*]
#   Hash of optional keys. Example:
#   { "root-key-1" => { priv => '<private key>', pub => '<public key>', type => 'rsa', user => 'root' } }
#
# [*ensure*]
#   Ensure present or absent for this user
#
# === Examples
#
#  users { 'foo':
#    group => 'bar',
#  }
#
# === Authors
#
# Alessandro De Salvo <Alessandro.DeSalvo@roma1.infn.it>
#
# === Copyright
#
# Copyright 2014 Alessandro De Salvo
#
define users (
    $user = undef,
    $groups = undef,
    $uid = undef,
    $gid = undef,
    $group = undef,
    $homepath = '/home',
    $ensure = 'present',
    $authorized_keys = undef,
    $keys = undef,
) {
    if ($user) { $username = $user } else { $username = $title }

    if ($username != 'root') {
        if ($uid) { $user_uid = {uid => $uid} } else { $user_uid = {} }
        if ($gid) { $user_gid = {gid => $gid} } else { $user_gid = {} }
        if ($groups) { $user_groups = {groups => $groups} } else { $user_groups = {} }
        if ($group) { $user_group = {group => $group} } else { $user_group = {} }
        $user_data = merge($user_uid,$user_gid,$user_groups,$user_group)
        $user_hash = { "$username" => $user_data }
        $user_defaults = {
            ensure => $ensure,
            managehome => true,
            home => "${homepath}/${username}",
            purge_ssh_keys => true
            shell => '/bin/bash'
        }
        create_resources(user, $user_hash, $user_defaults)
        $user_req = User[$username]
        $ssh_dir = "${homepath}/${username}/.ssh"
    } else {
        $user_req = []
        $ssh_dir = "/${username}/.ssh"
    }

    if ($ensure == 'present') {
        file {$ssh_dir:
            ensure  => directory,
            owner   => $username,
            group   => $group,
            mode    => 700,
            require => $user_req,
        }

        if ($keys) {
            if ($group) { $key_group = $group } else { $key_group = $username }
            $keys_defaults = {
                user   => $username,
                group  => $key_group,
                sshdir => "${ssh_dir}",
                type   => 'ssh-rsa',
                require => File[$ssh_dir],
            }
            create_resources (users::config_ssh_keys, $keys, $keys_defaults)
        }

        if ($authorized_keys) {
            $ak_defaults = {
                type   => 'ssh-rsa',
                ensure => present,
                user   => $username,
                require => File[$ssh_dir],
            }
            create_resources (ssh_authorized_key, $authorized_keys, $ak_defaults)
        }
    }
}
