define users::config_ssh_keys ($priv, $pub, $type, $user, $group, $sshdir) {
    case $type {
        'ssh-rsa': { $sshtype = 'rsa' }
        'ssh-dsa': { $sshtype = 'dsa' }
    }    

    file {"${title}-priv":
        path    => "${sshdir}/id_${sshtype}",
        owner   => $user,
        group   => $group,
        mode    => 0400,
        content => $priv,
    }

    file {"${title}-pub":
        path    => "${sshdir}/id_${sshtype}.pub",
        owner   => $user,
        group   => $group,
        mode    => 0600,
        content => "ssh-${sshtype} $pub ${title}",
    }
}
