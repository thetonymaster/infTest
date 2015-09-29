class web {
package { 'git':
  ensure => 'latest',
}
package { 'ruby':
  ensure => 'latest',
}

nginx::resource::vhost { 'tequilaware.com':
  www_root => '/var/www/tequilaware.com ',
}
  
vcsrepo { '/var/www/tequilaware.com':
  ensure     => 'latest',
  provider   => git,
  source     => 'https://github.com/ramonbadillo/webpage.git',
  submodules => false,
}  
}