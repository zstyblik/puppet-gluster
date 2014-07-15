class gluster::repo::rpm (
  $repo_key_name = $::gluster::params::repo_gpg_key_name,
  $repo_key_path = $::gluster::params::repo_gpg_key_path,
  $repo_key_source = $::gluster::params::repo_gpg_key_source,
) inherits ::gluster::repo {

  # basic sanity check
  if ! $version {
    fail ('Version not specified: unable to define repo!')
  }

  $repo_base = 'https://download.gluster.org/pub/gluster/glusterfs/'
  if $version == "LATEST" {
    $repo_ver = $version
  } else {
    if $version =~ /^\d\.\d$/ {
      $repo_ver = "${version}/LATEST/"
    } elsif $version =~ /^(\d)\.(\d)\.(\d)$/ {
      $repo_ver = "${1}.${2}/${version}/"
    } else {
      fail("${version} doesn't make sense!") 
    }
  }

  # the Gluster repo only supports x86_64 and i386
  $arch = $::architecture ? {
    'x86_64' => 'x86_64',
    /i\d86/  => 'i386',
    default  => false,
  }
  if ! $arch {
    fail("Architecture ${::architecture} not yet supported.")
  }

  $repo_url = "${repo_base}/${repo_ver}/RHEL/epel-${::operatingsystemrelease}/${arch}/"
  $repo_key = "${repo_key_path}${repo_key_name}"
  if $repo_key_source {
    file { $repo_key:
      ensure => file,
      source => "${repo_key_source}",
      before => Yumrepo["glusterfs-${arch}"],
    }
  }

  yumrepo { "glusterfs-${arch}":
    enabled  => 1,
    baseurl  => $repo_url,
    descr    => "GlusterFS ${arch}",
    gpgcheck => 1,
    gpgkey   => "file://${repo_key}",
  }

}